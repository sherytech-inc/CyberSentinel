import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_cleanup_coordinator.dart';
import '../services/websocket_service.dart';
import '../utils/date_parser.dart';
import '../models/capture_session.dart';

class DashboardProvider extends ChangeNotifier {
  // Threat Score
  int? _currentSessionThreatScore;
  int? get currentSessionThreatScore => _currentSessionThreatScore;
  int? _lastSessionThreatScore;
  int? get lastSessionThreatScore => _lastSessionThreatScore;
  int get threatScore =>
      (isMonitoringActive
          ? _currentSessionThreatScore
          : _lastSessionThreatScore) ??
      0;
  bool get hasReliableThreatScore => isMonitoringActive
      ? _currentSessionThreatScore != null
      : _lastSessionThreatScore != null;
  CaptureSessionSummary? _lastSession;
  CaptureSessionSummary? get lastSession => _lastSession;
  List<TrafficData> _lastSessionTrafficData = [];

  // KPI Counters
  int _activeThreatsCount = 0;
  int get activeThreatsCount => _activeThreatsCount;

  final Map<String, String> _currentPacketStates = {};
  final Map<String, String> _currentPacketPredictions = {};
  int get totalPacketsCount => capturedPacketsCount;
  int get capturedPacketsCount => isMonitoringActive
      ? _currentPacketStates.length
      : (_lastSession?.captured ?? 0);
  int get analyzedPacketsCount => isMonitoringActive
      ? _currentPacketStates.values
          .where((status) => status == 'complete' || status == 'partial')
          .length
      : (_lastSession?.analyzed ?? 0);
  int get completePacketsCount => isMonitoringActive
      ? _currentPacketStates.values
          .where((status) => status == 'complete')
          .length
      : (_lastSession?.complete ?? 0);
  int get partialPacketsCount => isMonitoringActive
      ? _currentPacketStates.values
          .where((status) => status == 'partial')
          .length
      : (_lastSession?.partial ?? 0);
  int get pendingPacketsCount => isMonitoringActive
      ? _currentPacketStates.values
          .where((status) => status == 'pending')
          .length
      : 0;
  double get analysisCompletion => capturedPacketsCount == 0
      ? 0
      : analyzedPacketsCount / capturedPacketsCount;
  int get failedPacketsCount => isMonitoringActive
      ? _currentPacketStates.values.where((status) => status == 'failed').length
      : (_lastSession?.failed ?? 0);
  int get deferredPacketsCount => isMonitoringActive
      ? _currentPacketStates.values
          .where((status) => status == 'deferred')
          .length
      : (_lastSession?.deferred ?? 0);
  int get notAnalyzedPacketsCount => isMonitoringActive
      ? _currentPacketStates.values
          .where((status) => status == 'cancelled' || status == 'not_analyzed')
          .length
      : (_lastSession?.notAnalyzed ?? 0);

  int _suspiciousIPsCount = 0;
  int get suspiciousIPsCount => _suspiciousIPsCount;

  // Traffic Data for Real-time Chart
  List<TrafficData> _trafficData = [];
  List<TrafficData> get trafficData =>
      isMonitoringActive ? _trafficData : _lastSessionTrafficData;

  // Alerts
  List<Alert> _alerts = [];
  List<Alert> get alerts => _alerts;

  // Malicious IPs
  List<MaliciousIP> _maliciousIPs = [];
  List<MaliciousIP> get maliciousIPs => _maliciousIPs;

  // Packet Classification
  int _normalCount = 0;
  int _suspiciousCount = 0;
  int _maliciousCount = 0;
  int get normalCount =>
      isMonitoringActive ? _normalCount : (_lastSession?.normal ?? 0);
  int get suspiciousCount =>
      isMonitoringActive ? _suspiciousCount : (_lastSession?.suspicious ?? 0);
  int get maliciousCount =>
      isMonitoringActive ? _maliciousCount : (_lastSession?.malicious ?? 0);
  int get unknownCount => isMonitoringActive
      ? (analyzedPacketsCount -
              _normalCount -
              _suspiciousCount -
              _maliciousCount)
          .clamp(0, 1 << 31)
      : (_lastSession?.unknown ?? 0);

  String? _currentHighestSeverity;

  // Last totals for delta calculation
  int _lastNormalCount = 0;
  int _lastSuspiciousCount = 0;
  int _lastMaliciousCount = 0;
  bool _firstStatsReceived = false;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // Capture Diagnostics
  Map<String, dynamic> _captureDiagnostics = {};
  Map<String, dynamic> get captureDiagnostics => _captureDiagnostics;
  bool _sessionInProgress = false;

  Timer? _refreshTimer;
  bool _isWsConnected = false;
  bool get isWsConnected => _isWsConnected;
  bool get isMonitoringActive {
    final state = _captureDiagnostics['state']?.toString().toLowerCase();
    return state == 'running' || state == 'replay';
  }

  DateTime _lastTrafficUpdate = DateTime.now();

  StreamSubscription? _wsStateSubscription;
  StreamSubscription? _wsInitialStateSubscription;
  StreamSubscription? _wsStatsSubscription;
  StreamSubscription? _wsPacketBatchSubscription;
  StreamSubscription? _wsPacketAnalysisUpdateSubscription;
  StreamSubscription? _wsNewThreatSubscription;
  StreamSubscription? _wsAlertUpdatedSubscription;
  StreamSubscription? _wsAlertResolvedSubscription;
  StreamSubscription? _authSubscription;
  bool _hasInitializedAuthenticatedState = false;

  DashboardProvider({bool initializeAuth = true}) {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    _initializeTrafficData();
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
          fetchDashboardData();
          _startAutoRefresh();
          _initWebSocket();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _hasInitializedAuthenticatedState = false;
        _refreshTimer?.cancel();
        _refreshTimer = null;
        WebSocketService().disconnect();
      }
    });
  }

  void _initializeTrafficData() {
    _lastTrafficUpdate = DateTime.now();
    _trafficData.clear();
  }

  void updateRefreshInterval(Duration? interval) {
    _refreshTimer?.cancel();
    if (interval != null) {
      _refreshTimer = Timer.periodic(interval, (_) {
        fetchDashboardData();
      });
    }
  }

  void _startAutoRefresh() {
    // Initial fallback, will be overridden by ProxyProvider
    updateRefreshInterval(const Duration(seconds: 30));
  }

  void _initWebSocket() {
    final ws = WebSocketService();
    ws.connect();

    _wsStateSubscription = ws.connectionStateStream.listen((connected) {
      _isWsConnected = connected == WebSocketState.connected;
      notifyListeners();
    });

    _wsInitialStateSubscription = ws.initialStateStream.listen((payload) {
      _parseInitialState(payload);
    });

    _wsStatsSubscription = ws.statsUpdateStream.listen((payload) {
      _parseStats(payload);
    });

    _wsPacketBatchSubscription = ws.packetBatchStream.listen((payload) {
      _applyPacketBatch(payload);
    });

    _wsPacketAnalysisUpdateSubscription =
        ws.packetAnalysisUpdateStream.listen((payload) {
      _applyAnalysisUpdate(payload);
    });

    _wsNewThreatSubscription = ws.newThreatStream.listen((payload) {
      _parseNewThreat(payload);
    });

    _wsAlertUpdatedSubscription = ws.alertUpdatedStream.listen((payload) {
      _parseAlertUpdated(payload);
    });

    _wsAlertResolvedSubscription = ws.alertResolvedStream.listen((payload) {
      _parseAlertUpdated(payload);
    });
  }

  void _parseInitialState(Map<String, dynamic> payload) {
    try {
      final stats = payload['stats'] as Map<String, dynamic>? ?? {};
      _parseStats(stats);

      final alertsData = payload['latest_alerts'] as List<dynamic>? ?? [];
      _alerts = alertsData.map((item) => _parseAlertItem(item)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void _parseStats(Map<String, dynamic> stats) {
    final snapshot = stats['snapshot'] as Map<String, dynamic>? ?? {};
    final diagnostics =
        snapshot['capture_diagnostics'] as Map<String, dynamic>? ??
            stats['capture_diagnostics'] as Map<String, dynamic>?;
    if (diagnostics != null) _applyCaptureDiagnostics(diagnostics);

    // activeThreatsCount = OPEN + INVESTIGATING alerts
    final open = stats['open_alerts'] as int? ?? 0;
    final inv = stats['investigating_alerts'] as int? ?? 0;
    _activeThreatsCount = open + inv;

    _suspiciousIPsCount =
        stats['suspicious_ips_count'] as int? ?? _suspiciousIPsCount;

    _updateTrafficData();
    notifyListeners();
  }

  void _parseNewThreat(Map<String, dynamic> item) {
    final alert = _parseAlertItem(item);
    _alerts.insert(0, alert);
    if (_alerts.length > 5) {
      _alerts.removeLast();
    }
    notifyListeners();
  }

  void _parseAlertUpdated(Map<String, dynamic> item) {
    final alertId = item['alert_id']?.toString() ?? '';
    final ip = item['source_ip']?.toString() ?? '';

    final idx = _alerts.indexWhere(
        (a) => a.id == alertId || (ip.isNotEmpty && a.title.contains(ip)));
    if (idx != -1) {
      final old = _alerts[idx];
      final score = (item['threat_score'] as num?)?.toDouble() ?? 80;
      final classification = item['model1_classification'] as String?;
      final threatType = (classification != null && classification.isNotEmpty)
          ? classification
          : 'Suspicious Traffic';
      _alerts[idx] = Alert(
        id: alertId.isNotEmpty ? alertId : old.id,
        title: threatType,
        description:
            'Source: ${ip.isNotEmpty ? ip : "Unknown"}\n${item['summary'] as String? ?? old.description.split('\n').last}',
        time: 'Just now',
        severity: _parseSeverity(score),
      );
      notifyListeners();
    } else {
      _fetchRecentAlerts();
    }
  }

  Alert _parseAlertItem(dynamic item) {
    final score = (item['threat_score'] as num?)?.toDouble() ?? 0;
    final reasoning = item['reasoning'] as List<dynamic>? ?? [];
    final scoredAt = item['scored_at'] as String? ?? '';
    String timeAgo = '';
    if (scoredAt.isNotEmpty) {
      final dt = DateParser.safeParse(scoredAt);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes} min ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } else {
        timeAgo = 'Unknown time';
      }
    }

    final classification = item['model1_classification'] as String?;
    final threatType = (classification != null && classification.isNotEmpty)
        ? classification
        : 'Suspicious Traffic';
    final sourceIp = item['source_ip']?.toString() ?? 'Unknown IP';
    final extraDesc = reasoning.isNotEmpty
        ? reasoning.first.toString()
        : (item['summary'] as String? ?? 'Score: ${score.toStringAsFixed(1)}');

    return Alert(
      id: item['alert_id']?.toString() ?? item['id']?.toString() ?? '',
      title: threatType,
      description: 'Source: $sourceIp\n$extraDesc',
      time: timeAgo,
      severity: _parseSeverity(score),
    );
  }

  AlertSeverity _parseSeverity(double score) {
    if (score > 90) return AlertSeverity.critical;
    if (score > 75) return AlertSeverity.high;
    if (score > 50) return AlertSeverity.medium;
    return AlertSeverity.low;
  }

  Future<void> fetchDashboardData() async {
    try {
      _isLoading = _alerts.isEmpty;
      _error = null;

      final stats = await LocalAgentClient.getDashboardStats();

      if (stats.containsKey('error') && stats['error'] == true) {
        _error = stats['message'] as String? ?? 'Failed to load dashboard data';
        notifyListeners();
        return;
      }

      final snapshot = stats['snapshot'] as Map<String, dynamic>? ?? {};
      final incomingDiagnostics =
          snapshot['capture_diagnostics'] as Map<String, dynamic>? ??
              stats['capture_diagnostics'] as Map<String, dynamic>?;
      if (incomingDiagnostics != null) {
        _applyCaptureDiagnostics(incomingDiagnostics);
      }
      _activeThreatsCount = stats['active_threats_count'] as int? ?? 0;
      _suspiciousIPsCount = stats['suspicious_ips_count'] as int? ?? 0;

      _updateTrafficData();

      final ipsData = stats['malicious_ips'] as List<dynamic>? ?? [];
      _maliciousIPs = ipsData
          .map((ip) => MaliciousIP(
                ip: ip['ip'] as String? ?? '',
                country: ip['country'] as String? ?? 'Unknown',
                requests: ip['requests'] as int? ?? 0,
                threatLevel: ip['threat_level'] as String? ?? 'High',
              ))
          .toList();

      await _fetchRecentAlerts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRecentAlerts() async {
    try {
      final result = await LocalAgentClient.getThreats(page: 1, pageSize: 5);
      if (result.containsKey('error') && result['error'] == true) return;

      final items = result['items'] as List<dynamic>? ?? [];
      _alerts = items.map((item) => _parseAlertItem(item)).toList();
      notifyListeners();
    } catch (_) {
      // Keep existing alerts on error
    }
  }

  void _updateTrafficData() {
    if (!_firstStatsReceived) {
      _lastNormalCount = _normalCount;
      _lastSuspiciousCount = _suspiciousCount;
      _lastMaliciousCount = _maliciousCount;
      _firstStatsReceived = true;
      return; // Skip first update to avoid huge initial spike
    }

    int normalDelta = _normalCount - _lastNormalCount;
    int suspDelta = _suspiciousCount - _lastSuspiciousCount;
    int malDelta = _maliciousCount - _lastMaliciousCount;

    // Handle database clears
    if (normalDelta < 0) normalDelta = 0;
    if (suspDelta < 0) suspDelta = 0;
    if (malDelta < 0) malDelta = 0;

    final now = DateTime.now();
    if (now.difference(_lastTrafficUpdate).inSeconds < 5) {
      if (_trafficData.isNotEmpty) {
        final last = _trafficData.last;
        _trafficData.last = TrafficData(
          time: last.time,
          normal: last.normal + normalDelta,
          suspicious: last.suspicious + suspDelta,
          malicious: last.malicious + malDelta,
          pending: last.pending,
        );
      }
    } else {
      if (_trafficData.length >= 24) {
        _trafficData.removeAt(0);
      }
      _trafficData.add(TrafficData(
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        normal: normalDelta,
        suspicious: suspDelta,
        malicious: malDelta,
        pending: 0,
      ));
      _lastTrafficUpdate = now;
    }

    _lastNormalCount = _normalCount;
    _lastSuspiciousCount = _suspiciousCount;
    _lastMaliciousCount = _maliciousCount;
  }

  void _recordRawTraffic(int count) {
    final now = DateTime.now();
    if (_trafficData.isNotEmpty &&
        now.difference(_lastTrafficUpdate).inSeconds < 5) {
      final last = _trafficData.last;
      _trafficData.last = TrafficData(
        time: last.time,
        normal: last.normal,
        suspicious: last.suspicious,
        malicious: last.malicious,
        pending: last.pending + count,
      );
      return;
    }
    if (_trafficData.length >= 24) _trafficData.removeAt(0);
    _trafficData.add(TrafficData(
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
      normal: 0,
      suspicious: 0,
      malicious: 0,
      pending: count,
    ));
    _lastTrafficUpdate = now;
  }

  void _applyPacketBatch(Map<String, dynamic> payload) {
    final packets = payload['packets'] as List<dynamic>? ?? const [];
    if (packets.isEmpty) return;
    _applyCaptureDiagnostics({
      ..._captureDiagnostics,
      'state': 'running',
    });
    var added = 0;
    for (final item in packets) {
      if (item is! Map) continue;
      final id = item['packet_id']?.toString() ?? item['id']?.toString() ?? '';
      if (id.isEmpty || _currentPacketStates.containsKey(id)) continue;
      _currentPacketStates[id] =
          item['analysis_status']?.toString().toLowerCase() ?? 'pending';
      added++;
    }
    if (added > 0) _recordRawTraffic(added);
    notifyListeners();
  }

  void _applyAnalysisUpdate(Map<String, dynamic> payload) {
    final status = payload['analysis_status']?.toString().toLowerCase() ?? '';
    final packetIds = (payload['packet_ids'] as List<dynamic>? ?? const [])
        .map((id) => id.toString())
        .where(_currentPacketStates.containsKey)
        .toSet();
    if (packetIds.isEmpty) return;
    for (final id in packetIds) {
      _currentPacketStates[id] = status;
    }
    if (status == 'complete' || status == 'partial') {
      final prediction = payload['ml_prediction']?.toString().toLowerCase();
      if (prediction != null) {
        for (final id in packetIds) {
          final previous = _currentPacketPredictions[id];
          if (previous == prediction) continue;
          _adjustPrediction(previous, -1);
          _currentPacketPredictions[id] = prediction;
          _adjustPrediction(prediction, 1);
        }
      }
      final score = (payload['threat_score'] as num?)?.round();
      if (score != null) {
        _currentSessionThreatScore = score;
        final severity = _severityForScore(score);
        if (_severityRank(severity) > _severityRank(_currentHighestSeverity)) {
          _currentHighestSeverity = severity;
        }
      }
    }
    notifyListeners();
  }

  void _adjustPrediction(String? prediction, int delta) {
    if (prediction == 'malicious') {
      _maliciousCount = (_maliciousCount + delta).clamp(0, 1 << 31);
    } else if (prediction == 'suspicious') {
      _suspiciousCount = (_suspiciousCount + delta).clamp(0, 1 << 31);
    } else if (prediction == 'normal' || prediction == 'benign') {
      _normalCount = (_normalCount + delta).clamp(0, 1 << 31);
    }
  }

  String _severityForScore(int score) {
    if (score >= 70) return 'Critical';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  int _severityRank(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return 3;
      case 'high':
        return 2;
      case 'medium':
        return 1;
      case 'low':
        return 0;
      default:
        return -1;
    }
  }

  void _applyCaptureDiagnostics(Map<String, dynamic> diagnostics) {
    _captureDiagnostics = Map<String, dynamic>.from(diagnostics);
    final state = _captureDiagnostics['state']?.toString().toLowerCase();
    final beginsSession = state == 'starting' ||
        state == 'running' ||
        state == 'replay' ||
        state == 'stopping';
    if (!_sessionInProgress && beginsSession) {
      // A new session must establish its own live evidence.
      _sessionInProgress = true;
      _currentSessionThreatScore = null;
      _currentPacketStates.clear();
      _currentPacketPredictions.clear();
      _normalCount = 0;
      _suspiciousCount = 0;
      _maliciousCount = 0;
      _currentHighestSeverity = null;
      _initializeTrafficData();
    } else if (_sessionInProgress && (state == 'stopped' || state == 'error')) {
      for (final entry in _currentPacketStates.entries.toList()) {
        if (entry.value == 'pending') {
          _currentPacketStates[entry.key] = 'not_analyzed';
        }
      }
      final complete = _currentPacketStates.values
          .where((value) => value == 'complete')
          .length;
      final partial = _currentPacketStates.values
          .where((value) => value == 'partial')
          .length;
      final failed = _currentPacketStates.values
          .where((value) => value == 'failed')
          .length;
      final deferred = _currentPacketStates.values
          .where((value) => value == 'deferred')
          .length;
      final notAnalyzed =
          _currentPacketStates.length - complete - partial - failed - deferred;
      final analyzed = complete + partial;
      _lastSession = CaptureSessionSummary(
        sessionId: _captureDiagnostics['session_id']?.toString() ?? '',
        status: state == 'error' ? 'failed' : 'completed',
        captureMode: 'live',
        interfaceName: _captureDiagnostics['interface']?.toString(),
        captured: _currentPacketStates.length,
        analyzed: analyzed,
        pending: 0,
        complete: complete,
        partial: partial,
        failed: failed,
        deferred: deferred,
        notAnalyzed: notAnalyzed.clamp(0, 1 << 31),
        normal: _normalCount,
        suspicious: _suspiciousCount,
        malicious: _maliciousCount,
        unknown: (analyzed - _normalCount - _suspiciousCount - _maliciousCount)
            .clamp(0, 1 << 31),
        lastReliableScore: _currentSessionThreatScore?.toDouble(),
        highestSeverity: analyzed > 0 ? _currentHighestSeverity : null,
      );
      // A session without reliable complete/valid partial analysis is N/A.
      _lastSessionThreatScore =
          analyzed > 0 ? _currentSessionThreatScore : null;
      _lastSessionTrafficData = [
        TrafficData(
          time: 'Start',
          normal: 0,
          suspicious: 0,
          malicious: 0,
          pending: 0,
        ),
        TrafficData(
          time: 'Final',
          normal: _normalCount,
          suspicious: _suspiciousCount,
          malicious: _maliciousCount,
          pending: notAnalyzed.clamp(0, 1 << 31),
        ),
      ];
      _currentSessionThreatScore = null;
      _sessionInProgress = false;
    }
  }

  @visibleForTesting
  void applyCaptureDiagnosticsForTesting(Map<String, dynamic> diagnostics) {
    _applyCaptureDiagnostics(diagnostics);
    notifyListeners();
  }

  @visibleForTesting
  void applyAnalysisUpdateForTesting(Map<String, dynamic> payload) {
    _applyAnalysisUpdate(payload);
  }

  @visibleForTesting
  void applyPacketBatchForTesting(Map<String, dynamic> payload) {
    _applyPacketBatch(payload);
  }

  @visibleForTesting
  void applyLastSessionForTesting(Map<String, dynamic> payload) {
    _lastSession = CaptureSessionSummary.fromJson(payload);
    _lastSessionThreatScore = _lastSession?.lastReliableScore?.round();
    _lastSessionTrafficData = [
      TrafficData(time: 'Start', normal: 0, suspicious: 0, malicious: 0),
      TrafficData(
        time: 'Final',
        normal: _lastSession?.normal ?? 0,
        suspicious: _lastSession?.suspicious ?? 0,
        malicious: _lastSession?.malicious ?? 0,
        pending: _lastSession?.notAnalyzed ?? 0,
      ),
    ];
    notifyListeners();
  }

  void clear() {
    _currentSessionThreatScore = null;
    _lastSessionThreatScore = null;
    _lastSession = null;
    _lastSessionTrafficData.clear();
    _activeThreatsCount = 0;
    _currentPacketStates.clear();
    _currentPacketPredictions.clear();
    _suspiciousIPsCount = 0;
    _trafficData.clear();
    _alerts.clear();
    _maliciousIPs.clear();
    _normalCount = 0;
    _suspiciousCount = 0;
    _maliciousCount = 0;
    _currentHighestSeverity = null;
    _lastNormalCount = 0;
    _lastSuspiciousCount = 0;
    _lastMaliciousCount = 0;
    _firstStatsReceived = false;
    _captureDiagnostics.clear();
    _sessionInProgress = false;
    _error = null;
    _isLoading = false;
    _refreshTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _refreshTimer?.cancel();
    _wsStateSubscription?.cancel();
    _wsInitialStateSubscription?.cancel();
    _wsStatsSubscription?.cancel();
    _wsPacketBatchSubscription?.cancel();
    _wsPacketAnalysisUpdateSubscription?.cancel();
    _wsNewThreatSubscription?.cancel();
    _wsAlertUpdatedSubscription?.cancel();
    _wsAlertResolvedSubscription?.cancel();
    super.dispose();
  }
}

class TrafficData {
  final String time;
  final int normal;
  final int suspicious;
  final int malicious;
  final int pending;

  TrafficData({
    required this.time,
    required this.normal,
    required this.suspicious,
    required this.malicious,
    this.pending = 0,
  });
}

class Alert {
  final String id;
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
  });
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

class MaliciousIP {
  final String ip;
  final String country;
  final int requests;
  final String threatLevel;

  MaliciousIP({
    required this.ip,
    required this.country,
    required this.requests,
    required this.threatLevel,
  });
}
