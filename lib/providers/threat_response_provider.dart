import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api/clients/local_agent_client.dart';
import '../models/response_action.dart';
import '../services/websocket_service.dart';
import 'session_cleanup_coordinator.dart';

enum ThreatAlertFilter {
  all('ALL', 'All'),
  open('OPEN', 'Open'),
  investigating('INVESTIGATING', 'Investigating'),
  resolved('RESOLVED', 'Resolved'),
  ignored('FALSE_POSITIVE', 'Ignored');

  const ThreatAlertFilter(this.status, this.label);
  final String status;
  final String label;
}

class ThreatResponseProvider extends ChangeNotifier {
  int _blockedIPsCount = 0;
  int _totalActions = 0;
  List<Map<String, dynamic>> _threatQueue = [];
  List<Map<String, dynamic>> _alertHistory = [];
  List<ResponseAction> _actionHistory = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  String? _expandedThreatId;
  ThreatAlertFilter _alertFilter = ThreatAlertFilter.all;
  final Set<String> _pendingActions = {};
  Future<void>? _fetchFuture;

  StreamSubscription? _newThreatSub;
  StreamSubscription? _alertUpdatedSub;
  StreamSubscription? _alertResolvedSub;

  ThreatResponseProvider({bool listenToWebSocket = true}) {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    if (listenToWebSocket) {
      _initWebSocket();
    }
  }

  int get activeThreats => _threatQueue.length;
  int get blockedIPsCount => _blockedIPsCount;
  int get totalActions => _totalActions;
  List<Map<String, dynamic>> get threatQueue => List.unmodifiable(_threatQueue);
  List<Map<String, dynamic>> get alertHistory =>
      List.unmodifiable(_alertHistory);
  List<Map<String, dynamic>> get filteredAlertHistory {
    if (_alertFilter == ThreatAlertFilter.all) {
      return alertHistory;
    }
    return List.unmodifiable(
      _alertHistory.where(
        (alert) =>
            alert['status']?.toString().toUpperCase() == _alertFilter.status,
      ),
    );
  }

  List<ResponseAction> get actionHistory => List.unmodifiable(_actionHistory);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  String? get expandedThreatId => _expandedThreatId;
  ThreatAlertFilter get alertFilter => _alertFilter;

  bool isActionPending(String alertId) => _pendingActions.contains(alertId);

  Future<void> ensureLoaded() => _hasLoaded ? Future.value() : fetchAll();

  Future<void> fetchAll() {
    final active = _fetchFuture;
    if (active != null) return active;
    final operation = _fetchAll();
    _fetchFuture = operation;
    return operation.whenComplete(() {
      if (identical(_fetchFuture, operation)) {
        _fetchFuture = null;
      }
    });
  }

  Future<void> _fetchAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        fetchOverview(notify: false),
        fetchThreatQueue(notify: false),
        fetchAlertHistory(notify: false),
        fetchActionHistory(notify: false),
      ]);
      _hasLoaded = true;
    } catch (_) {
      _error = 'Threat response data is temporarily unavailable.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchOverview({bool notify = true}) async {
    final data = await LocalAgentClient.getResponseOverview();
    _throwIfError(data);
    _blockedIPsCount = (data['blocked_ips'] as num?)?.toInt() ?? 0;
    _totalActions = (data['total_actions'] as num?)?.toInt() ?? 0;
    if (notify) notifyListeners();
  }

  Future<void> fetchThreatQueue({bool notify = true}) async {
    final data = await LocalAgentClient.getResponseThreats();
    _throwIfError(data);
    _threatQueue = _items(data);
    if (notify) notifyListeners();
  }

  Future<void> fetchAlertHistory({bool notify = true}) async {
    final data = await LocalAgentClient.getResponseThreatHistory();
    _throwIfError(data);
    _alertHistory = _items(data);
    if (notify) notifyListeners();
  }

  Future<void> fetchActionHistory({bool notify = true}) async {
    final data = await LocalAgentClient.getResponseHistory();
    _throwIfError(data);
    _actionHistory =
        _items(data).map(ResponseAction.fromJson).toList(growable: false);
    if (notify) notifyListeners();
  }

  void setAlertFilter(ThreatAlertFilter filter) {
    if (_alertFilter == filter) return;
    _alertFilter = filter;
    notifyListeners();
  }

  Future<Map<String, dynamic>> blockIP(
    String ip,
    String reason,
    String alertId,
  ) {
    return _recordedFirewallAction(
      alertId,
      () => LocalAgentClient.responseBlockIP(
        ip,
        reason: reason,
        alertId: alertId,
      ),
    );
  }

  Future<Map<String, dynamic>> unblockIP(
    String ip,
    String reason,
    String alertId,
  ) {
    return _recordedFirewallAction(
      alertId,
      () => LocalAgentClient.responseUnblockIP(
        ip,
        reason: reason,
        alertId: alertId,
      ),
    );
  }

  Future<Map<String, dynamic>> whitelistIP(
    String ip,
    String reason,
    String alertId,
  ) {
    return _recordedFirewallAction(
      alertId,
      () => LocalAgentClient.responseWhitelistIP(
        ip,
        reason: reason,
        alertId: alertId,
      ),
    );
  }

  Future<Map<String, dynamic>> _recordedFirewallAction(
    String alertId,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    return _runAlertAction(alertId, () async {
      final response = await action();
      _throwIfError(response);
      await _refreshAfterAction();
      final enforced = response['enforced'] == true;
      return {
        'success': true,
        'recorded': response['recorded'] != false,
        'enforced': enforced,
        'status': response['status'] ?? 'RECORDED_ONLY',
        'message': response['message'] ??
            (enforced
                ? 'The firewall action was enforced.'
                : 'The action was recorded but not enforced.'),
      };
    });
  }

  Future<Map<String, dynamic>> investigateThreat(String alertId) {
    return _runAlertAction(alertId, () async {
      final response = await LocalAgentClient.investigateThreat(alertId);
      _throwIfError(response);
      _mergeReturnedAlert(
        response,
        alertId: alertId,
        fallbackStatus: 'INVESTIGATING',
      );
      await _refreshAfterAction();
      return {
        'success': true,
        'message': 'Investigation started.',
      };
    });
  }

  Future<Map<String, dynamic>> resolveThreat(String alertId) {
    return _runAlertAction(alertId, () async {
      final response = await LocalAgentClient.resolveThreat(alertId);
      _throwIfError(response);
      _mergeReturnedAlert(
        response,
        alertId: alertId,
        fallbackStatus: 'RESOLVED',
      );
      await _refreshAfterAction();
      return {
        'success': true,
        'message': 'Alert marked done.',
      };
    });
  }

  Future<Map<String, dynamic>> ignoreThreat(String alertId) {
    return _runAlertAction(alertId, () async {
      final response = await LocalAgentClient.ignoreThreat(alertId);
      _throwIfError(response);
      _mergeReturnedAlert(
        response,
        alertId: alertId,
        fallbackStatus: 'FALSE_POSITIVE',
      );
      await _refreshAfterAction();
      return {
        'success': true,
        'message': 'Alert ignored and retained in history.',
      };
    });
  }

  Future<Map<String, dynamic>> _runAlertAction(
    String alertId,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (isActionPending(alertId)) {
      return {
        'success': false,
        'message': 'This action is already in progress.',
      };
    }
    _pendingActions.add(alertId);
    _error = null;
    notifyListeners();
    try {
      final result = await action();
      return result;
    } catch (_) {
      _error = 'The requested action could not be completed.';
      return {
        'success': false,
        'message': _error,
      };
    } finally {
      _pendingActions.remove(alertId);
      notifyListeners();
    }
  }

  Future<void> _refreshAfterAction() async {
    try {
      await Future.wait([
        fetchActionHistory(notify: false),
        fetchOverview(notify: false),
      ]);
    } catch (_) {
      // The authoritative action response remains valid if enrichment refresh
      // is temporarily unavailable.
    }
  }

  Future<Map<String, dynamic>?> fetchThreatExplanation(String alertId) async {
    final response = await LocalAgentClient.getThreatExplanation(alertId);
    if (response['error'] == true) return null;
    return response;
  }

  Future<List<dynamic>> fetchThreatNotes(String alertId) async {
    return LocalAgentClient.getThreatNotes(alertId);
  }

  Future<void> addThreatNote(String alertId, String note) async {
    final response = await LocalAgentClient.addThreatNote(alertId, note);
    _throwIfError(response);
  }

  void toggleExpanded(String alertId) {
    _expandedThreatId = _expandedThreatId == alertId ? null : alertId;
    notifyListeners();
  }

  void _initWebSocket() {
    final ws = WebSocketService();
    _newThreatSub = ws.newThreatStream.listen((alert) {
      _upsertHistory(alert);
      _upsertActive(alert);
      notifyListeners();
    });
    _alertUpdatedSub = ws.alertUpdatedStream.listen(_mergeWebSocketAlert);
    _alertResolvedSub = ws.alertResolvedStream.listen(_mergeWebSocketAlert);
  }

  void _mergeWebSocketAlert(Map<String, dynamic> alert) {
    final alertId = alert['alert_id']?.toString();
    if (alertId == null || alertId.isEmpty) {
      fetchAll();
      return;
    }
    _mergeAlert(alertId, alert);
    notifyListeners();
  }

  void _mergeReturnedAlert(
    Map<String, dynamic> response, {
    required String alertId,
    required String fallbackStatus,
  }) {
    final alert = response['alert'];
    if (alert is Map) {
      _mergeAlert(alertId, Map<String, dynamic>.from(alert));
    } else {
      _mergeAlert(alertId, {'status': fallbackStatus});
    }
  }

  void _mergeAlert(String alertId, Map<String, dynamic> update) {
    Map<String, dynamic>? existing;
    for (final alert in [..._threatQueue, ..._alertHistory]) {
      if (alert['alert_id']?.toString() == alertId) {
        existing = alert;
        break;
      }
    }
    final merged = <String, dynamic>{
      ...?existing,
      ...update,
      'alert_id': alertId,
    };
    _upsertHistory(merged);
    final status = merged['status']?.toString().toUpperCase();
    if (status == 'OPEN' || status == 'INVESTIGATING') {
      _upsertActive(merged);
    } else {
      _threatQueue.removeWhere(
        (alert) => alert['alert_id']?.toString() == alertId,
      );
    }
  }

  void _upsertActive(Map<String, dynamic> alert) {
    _upsert(_threatQueue, alert);
  }

  void _upsertHistory(Map<String, dynamic> alert) {
    _upsert(_alertHistory, alert);
  }

  static void _upsert(
    List<Map<String, dynamic>> records,
    Map<String, dynamic> alert,
  ) {
    final alertId = alert['alert_id']?.toString();
    if (alertId == null || alertId.isEmpty) return;
    final index = records.indexWhere(
      (record) => record['alert_id']?.toString() == alertId,
    );
    if (index == -1) {
      records.insert(0, Map<String, dynamic>.from(alert));
    } else {
      records[index] = {
        ...records[index],
        ...alert,
      };
    }
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic> data) {
    final items = data['items'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static void _throwIfError(Map<String, dynamic> response) {
    if (response['error'] == true) {
      throw StateError('response_unavailable');
    }
  }

  void clear() {
    _blockedIPsCount = 0;
    _totalActions = 0;
    _threatQueue = [];
    _alertHistory = [];
    _actionHistory = [];
    _error = null;
    _expandedThreatId = null;
    _alertFilter = ThreatAlertFilter.all;
    _pendingActions.clear();
    _hasLoaded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _newThreatSub?.cancel();
    _alertUpdatedSub?.cancel();
    _alertResolvedSub?.cancel();
    super.dispose();
  }
}
