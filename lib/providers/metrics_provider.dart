import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/global_metrics.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class MetricsProvider extends ChangeNotifier {
  GlobalSecurityMetrics _metrics = GlobalSecurityMetrics.empty();
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  StreamSubscription? _wsSubscription;

  GlobalSecurityMetrics get metrics => _metrics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MetricsProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    fetchMetrics();
    _startPolling();
    _listenToWebSocket();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchMetrics(silent: true);
    });
  }

  void _listenToWebSocket() {
    _wsSubscription = WebSocketService().statsUpdateStream.listen((event) {
      if (event['type'] == 'stats_update') {
        _handleWsStatsUpdate(event['data']);
      }
    });
  }

  Future<void> fetchMetrics({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final dashboardStats = await ApiService.getDashboardStats();

      final nextMetrics = GlobalSecurityMetrics.fromApi(
        dashboardStats: dashboardStats,
      );
      _error = null;

      if (_metrics == nextMetrics) {
        if (!silent) {
          _isLoading = false;
          notifyListeners();
        }
        return;
      }

      if (kDebugMode) {
        print('=== VERIFICATION LOG: Global Metrics ===');
        print('Source Dashboard API: snapshot=${dashboardStats['snapshot']}, period=${dashboardStats['period']}, score=${dashboardStats['threat_score']}');
        print('Final KPIs -> Active: ${nextMetrics.activeThreats}, Critical: ${nextMetrics.criticalThreats}, Score: ${nextMetrics.threatScore}');
      }
      
      _metrics = nextMetrics;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _handleWsStatsUpdate(Map<String, dynamic> stats) {
    // Attempt to merge WS stats into global metrics.
    // WS provides some but not all of the threat stats.
    final nextMetrics = _metrics.copyWith(
      activeThreats: stats['open_alerts'] != null && stats['investigating_alerts'] != null 
          ? (stats['open_alerts'] as int) + (stats['investigating_alerts'] as int) 
          : _metrics.activeThreats,
      threatScore: stats['threat_score'] ?? _metrics.threatScore,
      totalPackets: stats['total_packets_count'] ?? _metrics.totalPackets,
      suspiciousIps: stats['suspicious_ips_count'] ?? _metrics.suspiciousIps,
    );
    if (_metrics == nextMetrics) return;
    _metrics = nextMetrics;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _wsSubscription?.cancel();
    super.dispose();
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
