import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/response_action.dart';
import '../services/websocket_service.dart';

class ThreatResponseProvider extends ChangeNotifier {
  int _activeThreats = 0;
  int _blockedIPsCount = 0;
  int _totalActions = 0;
  List<Map<String, dynamic>> _threatQueue = [];
  List<ResponseAction> _actionHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _expandedThreatId;
  final Set<String> _pendingActions = {};

  bool isActionPending(String alertId) => _pendingActions.contains(alertId);

  StreamSubscription? _newThreatSub;
  StreamSubscription? _alertUpdatedSub;
  StreamSubscription? _alertResolvedSub;

  ThreatResponseProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    fetchAll();
    _initWebSocket();
  }

  int get activeThreats => _threatQueue.length;
  int get blockedIPsCount => _blockedIPsCount;
  int get totalActions => _totalActions;
  List<Map<String, dynamic>> get threatQueue => _threatQueue;
  List<ResponseAction> get actionHistory => _actionHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get expandedThreatId => _expandedThreatId;

  Future<void> fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchOverview(),
        fetchThreatQueue(),
        fetchActionHistory(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverview() async {
    try {
      final data = await LocalAgentClient.getResponseOverview();
      _activeThreats = data['active_threats'] ?? 0;
      _blockedIPsCount = data['blocked_ips'] ?? 0;
      _totalActions = data['total_actions'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching overview: $e');
    }
  }

  Future<void> fetchThreatQueue() async {
    try {
      final data = await LocalAgentClient.getResponseThreats();
      final items = data['items'] as List<dynamic>?;
      if (items != null) {
        _threatQueue = items.cast<Map<String, dynamic>>();
      } else {
        _threatQueue = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching threat queue: $e');
    }
  }

  Future<void> fetchActionHistory() async {
    try {
      final data = await LocalAgentClient.getResponseHistory();
      final items = data['items'] as List<dynamic>?;
      if (items != null) {
        _actionHistory = items
            .map((e) => ResponseAction.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _actionHistory = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching action history: $e');
    }
  }

  Future<Map<String, dynamic>> blockIP(
      String ip, String reason, String alertId) async {
    if (isActionPending(alertId))
      return {'success': false, 'message': 'Action pending'};
    _pendingActions.add(alertId);
    notifyListeners();
    try {
      final res = await LocalAgentClient.responseBlockIP(ip, reason: reason);
      if (res['error'] == true) {
        return {'success': false, 'message': res['message']};
      }
      return {
        'success': true,
        'message': res['message'] ?? 'Action recorded',
        'status': res['status'] ?? 'recorded_only'
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _pendingActions.remove(alertId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> unblockIP(
      String ip, String reason, String alertId) async {
    if (isActionPending(alertId))
      return {'success': false, 'message': 'Action pending'};
    _pendingActions.add(alertId);
    notifyListeners();
    try {
      final res = await LocalAgentClient.responseUnblockIP(ip, reason: reason);
      if (res['error'] == true)
        return {'success': false, 'message': res['message']};
      return {
        'success': true,
        'message': res['message'] ?? 'Action recorded',
        'status': res['status']
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _pendingActions.remove(alertId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> investigateThreat(String alertId) async {
    if (isActionPending(alertId))
      return {'success': false, 'message': 'Action pending'};
    _pendingActions.add(alertId);
    notifyListeners();
    try {
      final res = await LocalAgentClient.investigateThreat(alertId);
      if (res['error'] == true)
        return {'success': false, 'message': res['message']};
      return {'success': true, 'message': 'Investigation started'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _pendingActions.remove(alertId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> resolveThreat(String alertId) async {
    if (isActionPending(alertId))
      return {'success': false, 'message': 'Action pending'};
    _pendingActions.add(alertId);
    notifyListeners();
    try {
      final res = await LocalAgentClient.resolveThreat(alertId);
      if (res['error'] == true)
        return {'success': false, 'message': res['message']};
      return {'success': true, 'message': 'Alert resolved successfully'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _pendingActions.remove(alertId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> ignoreThreat(String alertId) async {
    if (isActionPending(alertId))
      return {'success': false, 'message': 'Action pending'};
    _pendingActions.add(alertId);
    notifyListeners();
    try {
      final res = await LocalAgentClient.ignoreThreat(alertId);
      if (res['error'] == true)
        return {'success': false, 'message': res['message']};
      return {'success': true, 'message': 'Alert ignored'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _pendingActions.remove(alertId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchThreatExplanation(String alertId) async {
    try {
      return await LocalAgentClient.getThreatExplanation(alertId);
    } catch (e) {
      debugPrint('Error fetching threat explanation: $e');
      return null;
    }
  }

  Future<List<dynamic>> fetchThreatNotes(String alertId) async {
    try {
      return await LocalAgentClient.getThreatNotes(alertId);
    } catch (e) {
      debugPrint('Error fetching threat notes: $e');
      return [];
    }
  }

  Future<void> addThreatNote(String alertId, String note) async {
    try {
      await LocalAgentClient.addThreatNote(alertId, note);
    } catch (e) {
      debugPrint('Error adding threat note: $e');
      throw Exception('Failed to add note');
    }
  }

  void toggleExpanded(String alertId) {
    if (_expandedThreatId == alertId) {
      _expandedThreatId = null;
    } else {
      _expandedThreatId = alertId;
    }
    notifyListeners();
  }

  void _initWebSocket() {
    final ws = WebSocketService();
    _newThreatSub = ws.newThreatStream.listen((_) => fetchThreatQueue());
    _alertUpdatedSub = ws.alertUpdatedStream.listen((_) => fetchThreatQueue());
    _alertResolvedSub =
        ws.alertResolvedStream.listen((_) => fetchThreatQueue());
  }

  @override
  void dispose() {
    _newThreatSub?.cancel();
    _alertUpdatedSub?.cancel();
    _alertResolvedSub?.cancel();
    super.dispose();
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
