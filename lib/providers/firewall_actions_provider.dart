import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/firewall_action_model.dart';
import '../services/api_service.dart';

class FirewallActionsProvider extends ChangeNotifier {
  List<FirewallActionModel> _actions = [];
  List<FirewallActionModel> get actions => _actions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int get blockCount => _actions.where((a) => a.action.toUpperCase() == 'BLOCK').length;
  int get unblockCount => _actions.where((a) => a.action.toUpperCase() == 'UNBLOCK').length;
  int get enforcedCount => _actions.where((a) => a.enforced).length;
  int get recordedCount => _actions.where((a) => a.recorded && !a.enforced).length;

  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Timer? _refreshTimer;

  FirewallActionsProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    fetchActions();
    _startAutoRefresh();
  }

  void updateRefreshInterval(Duration? interval) {
    _refreshTimer?.cancel();
    if (interval != null) {
      _refreshTimer = Timer.periodic(interval, (_) {
        if (!_isLoading && _currentPage == 1) {
          fetchActions(refresh: true);
        }
      });
    }
  }

  void _startAutoRefresh() {
    updateRefreshInterval(const Duration(seconds: 30));
  }

  Future<void> fetchActions({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await LocalAgentClient.fetchFirewallActions(
        page: _currentPage,
        pageSize: _pageSize,
      );

      final payload = result.containsKey('data') && result['data'] is Map
          ? result['data'] as Map<String, dynamic>
          : result;

      final List<dynamic> items = payload['items'] ?? [];
      final int total = payload['total'] ?? 0;

      final newActions = items
          .map((e) {
            try {
              return FirewallActionModel.fromJson(e as Map<String, dynamic>);
            } catch (err) {
              debugPrint('Error parsing action: $err');
              return null;
            }
          })
          .whereType<FirewallActionModel>()
          .toList();

      if (refresh) {
        _actions = newActions;
      } else {
        _actions.addAll(newActions);
      }

      _hasMore = _actions.length < total && newActions.isNotEmpty;
      if (_hasMore) {
        _currentPage++;
      }
    } catch (e) {
      _error = 'Failed to load firewall actions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
