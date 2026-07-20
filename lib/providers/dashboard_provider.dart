import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../utils/date_parser.dart';

class DashboardProvider extends ChangeNotifier {
  // Threat Score
  int _threatScore = 0;
  int get threatScore => _threatScore;

  // KPI Counters
  int _activeThreatsCount = 0;
  int get activeThreatsCount => _activeThreatsCount;

  int _totalPacketsCount = 0;
  int get totalPacketsCount => _totalPacketsCount;

  int _suspiciousIPsCount = 0;
  int get suspiciousIPsCount => _suspiciousIPsCount;

  // Traffic Data for Real-time Chart
  List<TrafficData> _trafficData = [];
  List<TrafficData> get trafficData => _trafficData;

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
  int get normalCount => _normalCount;
  int get suspiciousCount => _suspiciousCount;
  int get maliciousCount => _maliciousCount;

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

  Timer? _refreshTimer;
  bool _isWsConnected = false;
  bool get isWsConnected => _isWsConnected;

  DateTime _lastTrafficUpdate = DateTime.now();

  StreamSubscription? _wsStateSubscription;
  StreamSubscription? _wsInitialStateSubscription;
  StreamSubscription? _wsStatsSubscription;
  StreamSubscription? _wsNewThreatSubscription;
  StreamSubscription? _wsAlertUpdatedSubscription;
  StreamSubscription? _wsAlertResolvedSubscription;

  DashboardProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    _initializeTrafficData();
    fetchDashboardData();
    _startAutoRefresh();
    _initWebSocket();
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
    _threatScore = stats['threat_score'] as int? ?? _threatScore;
    
    // activeThreatsCount = OPEN + INVESTIGATING alerts
    final open = stats['open_alerts'] as int? ?? 0;
    final inv = stats['investigating_alerts'] as int? ?? 0;
    _activeThreatsCount = open + inv;

    _totalPacketsCount = stats['total_packets_count'] as int? ?? _totalPacketsCount;
    _suspiciousIPsCount = stats['suspicious_ips_count'] as int? ?? _suspiciousIPsCount;

    final classification = stats['packet_classification'] as Map<String, dynamic>? ?? {};
    _normalCount = classification['normal'] as int? ?? _normalCount;
    _suspiciousCount = classification['suspicious'] as int? ?? _suspiciousCount;
    _maliciousCount = classification['malicious'] as int? ?? _maliciousCount;

    _captureDiagnostics = stats['capture_diagnostics'] as Map<String, dynamic>? ?? _captureDiagnostics;

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
    
    final idx = _alerts.indexWhere((a) => a.id == alertId || (ip.isNotEmpty && a.title.contains(ip)));
    if (idx != -1) {
      final old = _alerts[idx];
      final score = (item['threat_score'] as num?)?.toDouble() ?? 80;
      final classification = item['model1_classification'] as String?;
      final threatType = (classification != null && classification.isNotEmpty) ? classification : 'Suspicious Traffic';
      _alerts[idx] = Alert(
        id: alertId.isNotEmpty ? alertId : old.id,
        title: threatType,
        description: 'Source: ${ip.isNotEmpty ? ip : "Unknown"}\n${item['summary'] as String? ?? old.description.split('\n').last}',
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
    final threatType = (classification != null && classification.isNotEmpty) ? classification : 'Suspicious Traffic';
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

      _threatScore = stats['threat_score'] as int? ?? 0;
      _activeThreatsCount = stats['active_threats_count'] as int? ?? 0;
      _totalPacketsCount = stats['total_packets_count'] as int? ?? 0;
      _suspiciousIPsCount = stats['suspicious_ips_count'] as int? ?? 0;

      final classification = stats['packet_classification'] as Map<String, dynamic>? ?? {};
      _normalCount = classification['normal'] as int? ?? 0;
      _suspiciousCount = classification['suspicious'] as int? ?? 0;
      _maliciousCount = classification['malicious'] as int? ?? 0;

      _captureDiagnostics = stats['capture_diagnostics'] as Map<String, dynamic>? ?? {};

      _updateTrafficData();

      final ipsData = stats['malicious_ips'] as List<dynamic>? ?? [];
      _maliciousIPs = ipsData.map((ip) => MaliciousIP(
        ip: ip['ip'] as String? ?? '',
        country: ip['country'] as String? ?? 'Unknown',
        requests: ip['requests'] as int? ?? 0,
        threatLevel: ip['threat_level'] as String? ?? 'High',
      )).toList();

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
        );
      }
    } else {
      if (_trafficData.length >= 24) {
        _trafficData.removeAt(0);
      }
      _trafficData.add(TrafficData(
        time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
        normal: normalDelta,
        suspicious: suspDelta,
        malicious: malDelta,
      ));
      _lastTrafficUpdate = now;
    }

    _lastNormalCount = _normalCount;
    _lastSuspiciousCount = _suspiciousCount;
    _lastMaliciousCount = _maliciousCount;
  }

  void clear() {
    _threatScore = 0;
    _activeThreatsCount = 0;
    _totalPacketsCount = 0;
    _suspiciousIPsCount = 0;
    _trafficData.clear();
    _alerts.clear();
    _maliciousIPs.clear();
    _normalCount = 0;
    _suspiciousCount = 0;
    _maliciousCount = 0;
    _lastNormalCount = 0;
    _lastSuspiciousCount = 0;
    _lastMaliciousCount = 0;
    _firstStatsReceived = false;
    _captureDiagnostics.clear();
    _error = null;
    _isLoading = false;
    _refreshTimer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _wsStateSubscription?.cancel();
    _wsInitialStateSubscription?.cancel();
    _wsStatsSubscription?.cancel();
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

  TrafficData({
    required this.time,
    required this.normal,
    required this.suspicious,
    required this.malicious,
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
