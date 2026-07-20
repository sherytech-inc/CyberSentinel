import 'package:cybersentinel/core/api/clients/cloud_control_plane_client.dart';
import 'session_cleanup_coordinator.dart';
import 'package:flutter/foundation.dart';
import '../models/report_kpis.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ReportsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _timeRange = '24h';
  String get timeRange => _timeRange;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  ReportKpis? get kpis {
    if (_dashboardData == null || _dashboardData!['kpis'] == null) return null;
    return ReportKpis.fromJson(_dashboardData!['kpis']);
  }

  List<dynamic> _snapshots = [];
  List<dynamic> get snapshots => _snapshots;

  bool _isSnapshotGenerating = false;
  bool get isSnapshotGenerating => _isSnapshotGenerating;

  final WebSocketService _wsService = WebSocketService();

  ReportsProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    _wsService.statsUpdateStream.listen((data) {
      if (!_isLoading) {
        fetchDashboard(silent: true);
      }
    });
  }

  void setTimeRange(String range) {
    if (_timeRange != range) {
      _timeRange = range;
      // Clear stale data so the UI does not display old KPIs
      // under the new time-range label while the request is in-flight.
      _dashboardData = null;
      notifyListeners();
      fetchDashboard();
    }
  }

  Future<void> fetchDashboard({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final data = await CloudControlPlaneClient.getReportingDashboard(_timeRange);
      if (data['error'] == true) {
        debugPrint('Error fetching reports dashboard: ${data['message']}');
      } else {
        _dashboardData = data;
      }
    } catch (e) {
      debugPrint('Exception fetching reports dashboard: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> fetchSnapshots() async {
    try {
      final data = await CloudControlPlaneClient.getReportSnapshots();
      if (data['error'] != true && data['data'] != null) {
        _snapshots = data['data']; // Assuming array is in 'data' or the response is a list
      } else if (data['items'] != null) {
        _snapshots = data['items'];
      }
    } catch (e) {
      debugPrint('Exception fetching snapshots: $e');
    }
    notifyListeners();
  }

  Future<void> createSnapshot() async {
    _isSnapshotGenerating = true;
    notifyListeners();
    
    try {
      final result = await CloudControlPlaneClient.createReportSnapshot(_timeRange);
      if (result['error'] != true) {
        await fetchSnapshots();
      }
    } finally {
      _isSnapshotGenerating = false;
      notifyListeners();
    }
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
