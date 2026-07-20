import 'dart:async';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/firewall_log.dart';
import '../services/api_service.dart';

class FirewallLogsProvider extends ChangeNotifier {
  bool _autoFetch = true;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  bool get autoFetch => _autoFetch;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<FirewallLog> _logs = [];

  FirewallLogsProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    fetchLogs();
    _startAutoRefresh();
  }

  void updateRefreshInterval(Duration? interval) {
    _refreshTimer?.cancel();
    if (interval != null) {
      _refreshTimer = Timer.periodic(interval, (_) {
        if (_autoFetch) fetchLogs();
      });
    }
  }

  void _startAutoRefresh() {
    updateRefreshInterval(const Duration(seconds: 15));
  }

  List<FirewallLog> get logs => _logs;

  int get blockedCount =>
      _logs.where((log) => log.action == FirewallAction.blocked).length;

  int get allowedCount =>
      _logs.where((log) => log.action == FirewallAction.allowed).length;

  List<FirewallLog> get blockedLogs =>
      _logs.where((log) => log.action == FirewallAction.blocked).take(5).toList();

  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// Fetch firewall logs from the backend API.
  Future<void> fetchLogs({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore) return;

    try {
      _isLoading = true;
      notifyListeners();

      final result = await ApiService.fetchFirewallLogs(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (result.containsKey('error') && result['error'] == true) {
        _error = result['message'] as String? ?? 'Failed to load firewall logs';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final payload = result.containsKey('data') && result['data'] is Map
          ? result['data'] as Map<String, dynamic>
          : result;

      final items = payload['items'] as List<dynamic>? ?? [];
      final total = payload['total'] as int? ?? 0;
      
      final newLogs = items
          .map((item) => FirewallLog.fromJson(item as Map<String, dynamic>))
          .toList();

      if (refresh) {
        _logs = newLogs;
      } else {
        _logs.addAll(newLogs);
      }

      _hasMore = _logs.length < total && newLogs.isNotEmpty;
      if (_hasMore) {
        _currentPage++;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleAutoFetch() {
    _autoFetch = !_autoFetch;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
