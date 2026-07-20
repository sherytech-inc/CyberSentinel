import 'package:cybersentinel/core/api/clients/cloud_control_plane_client.dart';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/intel_model.dart';
import '../services/api_service.dart';

class ThreatIntelProvider extends ChangeNotifier {
  ThreatIntelProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  String _searchQuery = '';
  IntelligenceResponse? _intelResponse;
  String? _errorMessage;
  bool _isLoading = false;
  int _lookupGeneration = 0;

  String get searchQuery => _searchQuery;
  IntelligenceResponse? get intelResponse => _intelResponse;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Runs unified multi-model analysis on the entered IP via the backend API.
  Future<void> analyzeIP() async {
    final query = _searchQuery.trim();

    if (query.isEmpty) {
      _errorMessage = 'Please enter an IP address.';
      _intelResponse = null;
      notifyListeners();
      return;
    }

    final ipv4Regex = RegExp(r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$');
    if (!ipv4Regex.hasMatch(query)) {
      _errorMessage = "'$query' is not a valid IPv4 address.";
      _intelResponse = null;
      notifyListeners();
      return;
    }

    final privatePrefixes = [
      '10.', '192.168.', '127.', '169.254.', '0.',
      for (int i = 16; i <= 31; i++) '172.$i.'
    ];

    for (var prefix in privatePrefixes) {
      if (query.startsWith(prefix)) {
        _errorMessage = "'$query' is a private/reserved address.";
        _intelResponse = null;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    final currentGen = ++_lookupGeneration;
    notifyListeners();

    try {
      final result = await CloudControlPlaneClient.analyzeIP(query);

      // Stale response protection
      if (currentGen != _lookupGeneration) return;

      if (result.containsKey('error') && result['error'] == true) {
        // Validation errors return 422 which maps to invalid_target
        // Or 503 which maps to unavailable
        // We handle the parsed IntelligenceResponse if backend returns it
        if (result.containsKey('ip') && result.containsKey('status')) {
           _intelResponse = IntelligenceResponse.fromJson(result);
           _errorMessage = null;
        } else {
           _errorMessage = result['message'] as String? ?? 'Analysis failed';
           _intelResponse = null;
        }
      } else {
        _intelResponse = IntelligenceResponse.fromJson(result);
        _errorMessage = null;
      }
    } catch (e) {
      if (currentGen != _lookupGeneration) return;
      _errorMessage = e.toString();
      _intelResponse = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearResults() {
    _intelResponse = null;
    _searchQuery = '';
    _errorMessage = null;
    _lookupGeneration++;
    notifyListeners();
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
