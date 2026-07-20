import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../services/api_service.dart';

class DemoProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  int _activeRuns = 0;
  int get activeRuns => _activeRuns;

  String? _activeRunId;
  String? get activeRunId => _activeRunId;

  String? _activeScenario;
  String? get activeScenario => _activeScenario;

  String? _error;
  String? get error => _error;

  DemoProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await LocalAgentClient.getDemoStatus();
      if (response['error'] == true) {
        _error = response['message'];
      } else {
        _isEnabled = response['enabled'] == true;
        _activeRuns = response['active_runs'] ?? 0;
        _activeRunId = response['active_run_id'];
        _activeScenario = response['active_scenario'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadScenario(String scenario) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await LocalAgentClient.triggerDemoMode(scenario);
      if (response['error'] == true) {
        throw Exception(response['message']);
      }
      await fetchStatus();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to load demo scenario: $e');
    }
  }

  Future<void> resetDemo() async {
    if (_activeRunId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await LocalAgentClient.resetDemoMode(_activeRunId!);
      if (response['error'] == true) {
        throw Exception(response['message']);
      }
      await fetchStatus();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to reset demo: $e');
    }
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
