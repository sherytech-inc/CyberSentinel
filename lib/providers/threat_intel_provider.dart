import 'dart:io';

import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/intel_model.dart';

typedef ThreatIntelRequest = Future<Map<String, dynamic>> Function(String ip);

class ThreatIntelProvider extends ChangeNotifier {
  ThreatIntelProvider({ThreatIntelRequest? request})
      : _request = request ?? LocalAgentClient.lookupThreatIntelligence {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  final ThreatIntelRequest _request;

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
    if (_isLoading) return;
    final query = _searchQuery.trim();

    if (query.isEmpty) {
      _errorMessage = 'Please enter an IP address.';
      _intelResponse = null;
      notifyListeners();
      return;
    }

    if (InternetAddress.tryParse(query) == null) {
      _errorMessage = "'$query' is not a valid IP address.";
      _intelResponse = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    final currentGen = ++_lookupGeneration;
    notifyListeners();

    try {
      final result = await _request(query);

      // Stale response protection
      if (currentGen != _lookupGeneration) return;

      if (result.containsKey('error') && result['error'] == true) {
        // Validation errors return 422 which maps to invalid_target
        // Or 503 which maps to unavailable
        // We handle the parsed IntelligenceResponse if backend returns it
        final data = result['data'];
        if (data is Map &&
            data.containsKey('ip') &&
            data.containsKey('status')) {
          _intelResponse =
              IntelligenceResponse.fromJson(Map<String, dynamic>.from(data));
          _errorMessage = null;
        } else {
          _errorMessage = result['message']?.toString() ?? 'Analysis failed';
          _intelResponse = null;
        }
      } else {
        _intelResponse = IntelligenceResponse.fromJson(result);
        _errorMessage = null;
      }
    } catch (e) {
      if (currentGen != _lookupGeneration) return;
      _errorMessage = 'Threat intelligence is temporarily unavailable.';
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
    _searchQuery = '';
    _intelResponse = null;
    _errorMessage = null;
    _isLoading = false;
    _lookupGeneration++;
    notifyListeners();
  }
}
