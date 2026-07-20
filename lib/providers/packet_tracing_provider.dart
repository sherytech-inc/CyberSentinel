import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/packet.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
enum CaptureState { stopped, starting, running, stopping, error, unavailable }

typedef DelayFunction = Future<void> Function(Duration duration);

class CaptureTransitionException implements Exception {
  final String message;
  CaptureTransitionException(this.message);
  @override
  String toString() => message;
}

class PacketTracingProvider extends ChangeNotifier {
  static const int maxVisiblePackets = 500;

  CaptureState _captureState = CaptureState.stopped;
  String? _selectedPacketId;
  Packet? _selectedPacket;
  int _totalPacketsReceived = 0;
  String _protocolFilter = 'all';
  String _riskFilter = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error; // Legacy error, kept for compatibility if used elsewhere
  String? captureError; // Detailed capture error
  
  Timer? _statusTimer;
  bool _statusRequestInFlight = false;
  bool _disposed = false;
  
  bool _isWsConnected = false;
  int _captureActionGeneration = 0;
  int _latestStatusRequest = 0;
  bool _captureActionPending = false;
  
  // Expose delay function for tests
  DelayFunction delay = Future<void>.delayed;

  CaptureState get captureState => _captureState;
  bool get isCapturing => _captureState == CaptureState.running;
  bool get isTransitioning => _captureState == CaptureState.starting || _captureState == CaptureState.stopping;
  String? get selectedPacketId => _selectedPacketId;
  Packet? get selectedPacket => _selectedPacket;
  String get protocolFilter => _protocolFilter;
  String get riskFilter => _riskFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalPacketsReceived => _totalPacketsReceived;

  List<Packet> _allPackets = [];
  StreamSubscription? _wsStateSubscription;
  StreamSubscription? _wsPacketBatchSubscription;

  PacketTracingProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    fetchPackets();
    _initWebSocket();
  }

  void _initWebSocket() {
    final ws = WebSocketService();
    ws.connect();

    _wsStateSubscription = ws.connectionStateStream.listen((state) {
      _isWsConnected = state == WebSocketState.connected;
      _adjustPollingState();
      notifyListeners();
    });

    _wsPacketBatchSubscription = ws.packetBatchStream.listen((payload) {
      _parsePacketBatch(payload);
    });
  }

  void _parsePacketBatch(Map<String, dynamic> payload) {
    try {
      final list = payload['packets'] as List<dynamic>? ?? [];
      final newPackets = list.map((item) => Packet.fromJson(item as Map<String, dynamic>)).toList();

      if (newPackets.isNotEmpty) {
        _totalPacketsReceived += newPackets.length;
        // Insert new packets at the beginning
        _allPackets.insertAll(0, newPackets);

        // Rolling buffer: keep only the most recent packets
        if (_allPackets.length > maxVisiblePackets) {
          _allPackets = _allPackets.sublist(0, maxVisiblePackets);
        }
        _reconcileSelection();
        notifyListeners();
      }
    } catch (_) {}
  }

  void _adjustPollingState() {
    if (_disposed) return;
    
    if (_captureState == CaptureState.running) {
      if (_isWsConnected) {
        // WS is connected, stop polling timer
        _statusTimer?.cancel();
        _statusTimer = null;
      } else {
        // WS is offline, start fallback polling timer if not already running
        if (_statusTimer == null) {
          _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
            if (!_disposed && !_statusRequestInFlight && !_captureActionPending) {
              _pollStatus();
            }
          });
        }
      }
    } else {
      _statusTimer?.cancel();
      _statusTimer = null;
    }
  }

  Future<void> _pollStatus() async {
    if (_statusRequestInFlight) return;
    _statusRequestInFlight = true;
    final requestId = ++_latestStatusRequest;

    try {
      final status = await LocalAgentClient.getCaptureStatus();
      if (requestId != _latestStatusRequest || _disposed || _captureActionPending) return;
      applyCaptureStatus(status);
      if (_captureState == CaptureState.running) {
        await fetchPackets();
      }
    } catch (_) {
      if (requestId == _latestStatusRequest && !_disposed && !_captureActionPending) {
        _captureState = CaptureState.unavailable;
        notifyListeners();
      }
    } finally {
      if (requestId == _latestStatusRequest) {
        _statusRequestInFlight = false;
      }
    }
  }

  @visibleForTesting
  void applyCaptureStatus(Map<String, dynamic> status) {
    if (_disposed) return;
    
    if (status.containsKey('error') && status['error'] == true) {
      _captureState = CaptureState.unavailable;
      captureError = status['message'] as String? ?? 'Status check failed';
      notifyListeners();
      return;
    }

    final backendState = status['state'] as String?;
    if (backendState == 'running' || backendState == 'replaying' || backendState == 'capturing') {
      _captureState = CaptureState.running;
    } else if (backendState == 'stopped' || backendState == 'idle') {
      _captureState = CaptureState.stopped;
    } else if (backendState == 'starting') {
      _captureState = CaptureState.starting;
    } else if (backendState == 'stopping') {
      _captureState = CaptureState.stopping;
    } else if (backendState == 'error') {
      _captureState = CaptureState.error;
      captureError = status['error'] as String? ?? 'Capture failed on backend.';
    } else {
      _captureState = CaptureState.unavailable;
    }
    _adjustPollingState();
    notifyListeners();
  }

  /// Returns the filtered packet list based on active protocol and risk filters.
  List<Packet> get packets {
    return _allPackets.where((packet) {
      // --- Protocol filter ---
      final bool protocolMatch = () {
        if (_protocolFilter == 'all') return true;
        if (_protocolFilter == 'http') {
          return packet.protocol.toUpperCase() == 'HTTP' ||
              packet.protocol.toUpperCase() == 'HTTPS';
        }
        return packet.protocol.toLowerCase() == _protocolFilter.toLowerCase();
      }();

      // --- Risk filter ---
      final bool riskMatch = () {
        if (_riskFilter == 'all') return true;
        switch (_riskFilter) {
          case 'normal':
            return packet.status == PacketStatus.benign;
          case 'suspicious':
            return packet.status == PacketStatus.suspicious;
          case 'malicious':
            return packet.status == PacketStatus.malicious;
          default:
            return true;
        }
      }();

      // --- Search filter ---
      final bool searchMatch = () {
        if (_searchQuery.isEmpty) return true;
        final query = _searchQuery.toLowerCase();
        return packet.ip.toLowerCase().contains(query) ||
               packet.protocol.toLowerCase().contains(query) ||
               packet.port.toString().contains(query);
      }();

      return protocolMatch && riskMatch && searchMatch;
    }).toList();
  }

  void _reconcileSelection() {
    final selectedId = _selectedPacketId;
    if (selectedId == null) return;

    final stillExists = _allPackets.any(
      (packet) => packet.stableId == selectedId,
    );

    if (!stillExists) {
      _selectedPacketId = null;
      _selectedPacket = null;
    }
  }

  /// Fetch packets from the backend API.
  Future<void> fetchPackets() async {
    try {
      _isLoading = _allPackets.isEmpty;
      _error = null;

      final result = await LocalAgentClient.getPackets(pageSize: maxVisiblePackets);

      if (result.containsKey('error') && result['error'] == true) {
        _error = result['message'] as String? ?? 'Failed to load packets';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final items = result['items'] as List<dynamic>? ?? [];
      final packets = items
          .map((item) => Packet.fromJson(item as Map<String, dynamic>))
          .toList();

      packets.sort((a, b) {
        final aTime = a.capturedAt;
        final bTime = b.capturedAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      _allPackets = packets;
      _reconcileSelection();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle packet capture on/off via the backend API.
  Future<void> toggleCapturing() async {
    if (_captureActionPending) return;

    final actionGeneration = ++_captureActionGeneration;
    _captureActionPending = true;
    captureError = null;

    try {
      final desiredRunning = _captureState != CaptureState.running;

      if (_captureState == CaptureState.running) {
        _captureState = CaptureState.stopping;
        notifyListeners();
        await LocalAgentClient.stopCapture();
      } else {
        _captureState = CaptureState.starting;
        notifyListeners();
        await LocalAgentClient.startCapture();
      }

      await _verifyCaptureTransition(
        expectedRunning: desiredRunning,
        actionGeneration: actionGeneration,
      );
    } catch (e) {
      if (e is CaptureTransitionException) {
        captureError = e.message;
      } else {
        captureError = e.toString();
        _captureState = CaptureState.unavailable;
      }
      notifyListeners();
    } finally {
      if (actionGeneration == _captureActionGeneration) {
        _captureActionPending = false;
        notifyListeners();
      }
    }
  }

  Future<void> _verifyCaptureTransition({
    required bool expectedRunning,
    required int actionGeneration,
  }) async {
    const maxAttempts = 5;
    const interval = Duration(milliseconds: 750);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (actionGeneration != _captureActionGeneration || _disposed) return;

      final requestId = ++_latestStatusRequest;
      final status = await LocalAgentClient.getCaptureStatus();

      if (actionGeneration != _captureActionGeneration || _disposed || requestId != _latestStatusRequest) return;

      applyCaptureStatus(status);

      if (_captureState == CaptureState.error) {
        throw CaptureTransitionException(
          status['error'] as String? ?? 'The capture daemon reported an error.',
        );
      }

      final reachedExpectedState = expectedRunning
          ? _captureState == CaptureState.running
          : _captureState == CaptureState.stopped;

      if (reachedExpectedState) {
        if (expectedRunning) {
          await fetchPackets();
        }
        return;
      }

      if (attempt < maxAttempts - 1) {
        await delay(interval);
      }
    }

    // After failure, perform one final authoritative refresh.
    try {
      final requestId = ++_latestStatusRequest;
      final finalStatus = await LocalAgentClient.getCaptureStatus();
      if (requestId == _latestStatusRequest && !_disposed) {
        applyCaptureStatus(finalStatus);
      }
    } catch (_) {
      _captureState = CaptureState.unavailable;
    }

    throw CaptureTransitionException(
      expectedRunning
          ? 'Capture did not start within the expected time.'
          : 'Capture did not stop within the expected time.',
    );
  }

  void selectPacketById(String id) {
    if (_selectedPacketId == id) {
      clearSelection();
    } else {
      _selectedPacketId = id;
      _selectedPacket = _allPackets.firstWhere((p) => p.stableId == id, orElse: () => _selectedPacket!);
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedPacketId != null) {
      _selectedPacketId = null;
      _selectedPacket = null;
      notifyListeners();
    }
  }

  /// ONLY FOR TESTING
  void injectMockPackets(List<Packet> mockPackets) {
    _allPackets = mockPackets;
    _reconcileSelection();
    notifyListeners();
  }

  void setProtocolFilter(String filter) {
    _protocolFilter = filter;
    if (_selectedPacketId != null &&
        !packets.any((p) => p.stableId == _selectedPacketId)) {
      clearSelection();
    }
    notifyListeners();
  }

  void setRiskFilter(String filter) {
    _riskFilter = filter;
    if (_selectedPacketId != null &&
        !packets.any((p) => p.stableId == _selectedPacketId)) {
      clearSelection();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (_selectedPacketId != null &&
        !packets.any((p) => p.stableId == _selectedPacketId)) {
      clearSelection();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _statusTimer?.cancel();
    _wsStateSubscription?.cancel();
    _wsPacketBatchSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void clear() {
    _captureState = CaptureState.stopped;
    _selectedPacketId = null;
    _selectedPacket = null;
    _totalPacketsReceived = 0;
    _protocolFilter = 'all';
    _riskFilter = 'all';
    _searchQuery = '';
    _isLoading = false;
    _error = null;
    captureError = null;
    _statusTimer?.cancel();
    _statusTimer = null;
    _statusRequestInFlight = false;
    _captureActionGeneration++;
    _captureActionPending = false;
    _allPackets.clear();
    notifyListeners();
  }
}
