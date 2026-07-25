import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_cleanup_coordinator.dart';
import '../models/packet.dart';
import '../services/websocket_service.dart';

enum CaptureState { stopped, starting, running, stopping, error, unavailable }

typedef DelayFunction = Future<void> Function(Duration duration);
typedef CaptureRequest = Future<Map<String, dynamic>> Function();
typedef StartCaptureRequest = Future<Map<String, dynamic>> Function(
    String interfaceName);
typedef CaptureStartedCallback = Future<void> Function();
typedef PacketHistoryRequest = Future<Map<String, dynamic>> Function(
    int pageSize);

class CaptureTransitionException implements Exception {
  final String message;
  CaptureTransitionException(this.message);
  @override
  String toString() => message;
}

class PacketTracingProvider extends ChangeNotifier {
  static const int maxVisiblePackets = 200;
  static const int historyPageSize = 200;
  static const Duration packetNotificationInterval =
      Duration(milliseconds: 150);

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
  bool _packetParseErrorLogged = false;
  Timer? _packetNotificationTimer;
  int _packetNotifications = 0;
  StreamSubscription? _authSubscription;
  bool _hasInitializedAuthenticatedState = false;

  // Expose delay function for tests
  DelayFunction delay = Future<void>.delayed;
  StartCaptureRequest startCaptureRequest =
      (interfaceName) => LocalAgentClient.startCapture(
            interfaceName: interfaceName,
          );
  CaptureRequest stopCaptureRequest = LocalAgentClient.stopCapture;
  CaptureRequest captureStatusRequest = LocalAgentClient.getCaptureStatus;
  late CaptureStartedCallback onCaptureStarted;
  PacketHistoryRequest packetHistoryRequest =
      (pageSize) => LocalAgentClient.getPackets(pageSize: pageSize);

  CaptureState get captureState => _captureState;
  bool get isCapturing => _captureState == CaptureState.running;
  bool get isTransitioning =>
      _captureState == CaptureState.starting ||
      _captureState == CaptureState.stopping;
  String? get selectedPacketId => _selectedPacketId;
  Packet? get selectedPacket => _selectedPacket;
  String get protocolFilter => _protocolFilter;
  String get riskFilter => _riskFilter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalPacketsReceived => _totalPacketsReceived;
  int get packetNotifications => _packetNotifications;
  int get pendingCount =>
      _allPackets.where((packet) => packet.analysisStatus == 'pending').length;

  List<Packet> _allPackets = [];
  final Map<String, int> _packetIndex = {};
  List<Packet>? _filteredPacketCache;
  StreamSubscription? _wsStateSubscription;
  StreamSubscription? _wsPacketBatchSubscription;
  StreamSubscription? _wsPacketAnalysisUpdateSubscription;

  PacketTracingProvider({bool initializeAuth = true}) {
    onCaptureStarted = () async {};
    SessionCleanupCoordinator.registerCleanupTask(clear);
    if (!initializeAuth) return;
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (session != null &&
          (event == AuthChangeEvent.initialSession ||
              event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.tokenRefreshed)) {
        if (!_hasInitializedAuthenticatedState) {
          _hasInitializedAuthenticatedState = true;
          _initWebSocket();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _hasInitializedAuthenticatedState = false;
        _statusTimer?.cancel();
        _statusTimer = null;
        WebSocketService().disconnect();
      }
    });
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
      applyPacketBatch(payload);
    });
    _wsPacketAnalysisUpdateSubscription =
        ws.packetAnalysisUpdateStream.listen(applyPacketAnalysisUpdate);
  }

  @visibleForTesting
  void applyPacketAnalysisUpdate(Map<String, dynamic> payload) {
    final ids = (payload['packet_ids'] as List<dynamic>? ?? const [])
        .map((id) => id.toString())
        .toSet();
    final flowId = payload['flow_id']?.toString() ?? '';
    if (ids.isEmpty && flowId.isEmpty) return;
    var changed = false;
    for (var index = 0; index < _allPackets.length; index++) {
      final packet = _allPackets[index];
      if (!ids.contains(packet.id) &&
          (flowId.isEmpty || packet.flowId != flowId)) {
        continue;
      }
      changed = true;
      _allPackets[index] = packet.withAnalysis(payload);
    }
    if (changed) {
      _invalidatePacketCache();
      _reconcileSelection();
      if (_selectedPacketId != null) {
        final index = _allPackets.indexWhere(
          (packet) => packet.stableId == _selectedPacketId,
        );
        _selectedPacket = index >= 0 ? _allPackets[index] : null;
      }
      _schedulePacketNotification();
    }
  }

  @visibleForTesting
  void applyPacketBatch(Map<String, dynamic> payload) {
    try {
      final list = payload['packets'] as List<dynamic>? ?? [];
      final newPackets = list
          .map((item) => Packet.fromJson(item as Map<String, dynamic>))
          .toList();

      if (newPackets.isNotEmpty) {
        final additions = <Packet>[];
        for (final packet in newPackets) {
          final existingIndex = _packetIndex[packet.id];
          if (existingIndex == null) {
            additions.add(packet);
            _totalPacketsReceived++;
          } else {
            _allPackets[existingIndex] = packet;
          }
        }
        if (additions.isNotEmpty) {
          _allPackets.insertAll(0, additions.reversed);
        }

        // Rolling buffer: keep only the most recent packets
        if (_allPackets.length > maxVisiblePackets) {
          _allPackets = _allPackets.sublist(0, maxVisiblePackets);
        }
        _rebuildPacketIndex();
        _invalidatePacketCache();
        _reconcileSelection();
        _schedulePacketNotification();
      }
    } catch (error) {
      if (!_packetParseErrorLogged && kDebugMode) {
        _packetParseErrorLogged = true;
        debugPrint(
            'Live packet event could not be parsed: ${error.runtimeType}');
      }
    }
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
            if (!_disposed &&
                !_statusRequestInFlight &&
                !_captureActionPending) {
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
      if (requestId != _latestStatusRequest ||
          _disposed ||
          _captureActionPending) return;
      applyCaptureStatus(status);
    } catch (error) {
      if (requestId == _latestStatusRequest &&
          !_disposed &&
          !_captureActionPending) {
        captureError = 'Capture status temporarily unavailable.';
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
      captureError = status['message'] as String? ?? 'Status check failed';
      notifyListeners();
      return;
    }

    final backendState = status['state'] as String?;
    if (backendState == 'running' ||
        backendState == 'replaying' ||
        backendState == 'capturing') {
      _captureState = CaptureState.running;
    } else if (backendState == 'stopped' || backendState == 'idle') {
      _captureState = CaptureState.stopped;
      _terminalizePendingPackets();
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
    return _filteredPacketCache ??= _allPackets.where((packet) {
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

  void _invalidatePacketCache() => _filteredPacketCache = null;

  void _rebuildPacketIndex() {
    _packetIndex.clear();
    for (var index = 0; index < _allPackets.length; index++) {
      _packetIndex[_allPackets[index].id] = index;
    }
  }

  void _schedulePacketNotification() {
    if (_packetNotificationTimer?.isActive == true) return;
    _packetNotificationTimer = Timer(packetNotificationInterval, () {
      if (_disposed) return;
      _packetNotifications++;
      notifyListeners();
    });
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
    // Historical records intentionally never enter the live packet collection.
    try {
      await packetHistoryRequest(historyPageSize);
    } catch (_) {
      // Database history is optional and must never obscure live capture.
    }
  }

  /// Toggle packet capture on/off via the backend API.
  Future<void> toggleCapturing({String interfaceName = 'en0'}) async {
    if (_captureActionPending) return;

    final actionGeneration = ++_captureActionGeneration;
    _captureActionPending = true;
    captureError = null;

    final desiredRunning = _captureState != CaptureState.running;

    try {
      if (_captureState == CaptureState.running) {
        _captureState = CaptureState.stopping;
        notifyListeners();
        final response = await stopCaptureRequest();
        _throwIfRequestFailed(response);
      } else {
        _captureState = CaptureState.starting;
        notifyListeners();
        final response = await startCaptureRequest(interfaceName);
        _throwIfRequestFailed(response);
      }

      await _verifyCaptureTransition(
        expectedRunning: desiredRunning,
        actionGeneration: actionGeneration,
      );
    } catch (e) {
      if (e is CaptureTransitionException) {
        captureError = e.message;
        _captureState =
            desiredRunning ? CaptureState.stopped : CaptureState.running;
      } else {
        captureError = e.toString();
        _captureState =
            desiredRunning ? CaptureState.stopped : CaptureState.running;
      }
      notifyListeners();
    } finally {
      if (actionGeneration == _captureActionGeneration) {
        if (captureError == null) {
          _error = null;
        }
        _captureActionPending = false;
        notifyListeners();
      }
    }
  }

  void _throwIfRequestFailed(Map<String, dynamic> response) {
    if (response['error'] == true) {
      throw CaptureTransitionException(
        response['message']?.toString() ?? 'Capture request failed.',
      );
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
      final status = await captureStatusRequest();

      if (actionGeneration != _captureActionGeneration ||
          _disposed ||
          requestId != _latestStatusRequest) return;

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
          _allPackets.clear();
          _packetIndex.clear();
          _totalPacketsReceived = 0;
          _invalidatePacketCache();
          await onCaptureStarted();
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
      final finalStatus = await captureStatusRequest();
      if (requestId == _latestStatusRequest && !_disposed) {
        applyCaptureStatus(finalStatus);
      }
    } catch (_) {}

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
      _selectedPacket = _allPackets.firstWhere((p) => p.stableId == id,
          orElse: () => _selectedPacket!);
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
    _rebuildPacketIndex();
    _invalidatePacketCache();
    _reconcileSelection();
    notifyListeners();
  }

  void setProtocolFilter(String filter) {
    _protocolFilter = filter;
    _invalidatePacketCache();
    if (_selectedPacketId != null &&
        !packets.any((p) => p.stableId == _selectedPacketId)) {
      clearSelection();
    }
    notifyListeners();
  }

  void setRiskFilter(String filter) {
    _riskFilter = filter;
    _invalidatePacketCache();
    if (_selectedPacketId != null &&
        !packets.any((p) => p.stableId == _selectedPacketId)) {
      clearSelection();
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _invalidatePacketCache();
    if (_selectedPacketId != null &&
        !packets.any((p) => p.stableId == _selectedPacketId)) {
      clearSelection();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _statusTimer?.cancel();
    _packetNotificationTimer?.cancel();
    _wsStateSubscription?.cancel();
    _wsPacketBatchSubscription?.cancel();
    _wsPacketAnalysisUpdateSubscription?.cancel();
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
    _packetIndex.clear();
    _invalidatePacketCache();
    notifyListeners();
  }

  void _terminalizePendingPackets() {
    var changed = false;
    for (var index = 0; index < _allPackets.length; index++) {
      if (_allPackets[index].analysisStatus != 'pending') continue;
      _allPackets[index] = _allPackets[index].withAnalysis({
        'analysis_status': 'not_analyzed',
        'severity': 'Stopped before analysis',
      });
      changed = true;
    }
    if (changed) {
      _invalidatePacketCache();
      _reconcileSelection();
    }
  }
}
