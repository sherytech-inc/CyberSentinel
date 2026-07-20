import 'session_cleanup_coordinator.dart';
import 'package:flutter/foundation.dart';
import '../models/integration_status.dart';
import '../services/api_service.dart';

class IntegrationsProvider extends ChangeNotifier {
  IntegrationsProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  IntegrationsResponse? _integrations;
  bool _isLoading = false;
  String? _error;
  
  final Map<String, bool> _testingStatus = {};
  final Map<String, IntegrationTestResponse> _testResults = {};

  IntegrationsResponse? get integrations => _integrations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isTesting(String provider) => _testingStatus[provider] ?? false;
  IntegrationTestResponse? getTestResult(String provider) => _testResults[provider];

  Future<void> fetchIntegrations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getIntegrations();
      _integrations = IntegrationsResponse.fromJson(response);
    } catch (e) {
      _error = 'Failed to load integrations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> testConnection(String provider) async {
    if (_testingStatus[provider] == true) return;

    _testingStatus[provider] = true;
    notifyListeners();

    try {
      final response = await ApiService.testIntegration(provider);
      final result = IntegrationTestResponse.fromJson(response);
      _testResults[provider] = result;
      
      // Update the main integrations object to reflect the new state
      if (_integrations != null) {
        if (provider == 'virustotal') {
          _integrations = IntegrationsResponse(
            virustotal: _updateStatus(_integrations!.virustotal, result),
            abuseipdb: _integrations!.abuseipdb,
            groq: _integrations!.groq,
          );
        } else if (provider == 'abuseipdb') {
          _integrations = IntegrationsResponse(
            virustotal: _integrations!.virustotal,
            abuseipdb: _updateStatus(_integrations!.abuseipdb, result),
            groq: _integrations!.groq,
          );
        } else if (provider == 'groq') {
          _integrations = IntegrationsResponse(
            virustotal: _integrations!.virustotal,
            abuseipdb: _integrations!.abuseipdb,
            groq: _updateStatus(_integrations!.groq, result),
          );
        }
      }
    } catch (e) {
      // Create a local failure result if the API call throws
      _testResults[provider] = IntegrationTestResponse(
        provider: provider,
        configured: true,
        state: 'unavailable',
        message: 'Connection failed or timed out.',
        testedAt: DateTime.now(),
      );
    } finally {
      _testingStatus[provider] = false;
      notifyListeners();
    }
  }

  IntegrationStatus _updateStatus(IntegrationStatus old, IntegrationTestResponse result) {
    return IntegrationStatus(
      provider: old.provider,
      configured: result.configured,
      state: result.state,
      message: result.message,
      maskedHint: old.maskedHint,
      lastCheckedAt: result.testedAt,
    );
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
