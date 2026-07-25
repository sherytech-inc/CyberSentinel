import 'package:flutter/foundation.dart';
import '../models/capture_capability.dart';
import '../core/api/clients/local_agent_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaptureCapabilityProvider extends ChangeNotifier {
  CaptureCapabilityResult? _capabilityResult;
  bool _isLoading = false;
  String? _error;
  bool _consentGiven = false;
  bool _setupCompleted = false;
  bool _setupPreferenceLoaded = false;
  String? _selectedInterfaceId;
  bool _consentGranted = false;

  static const _setupCompletedKey = 'capture_setup_completed';
  static const _selectedInterfaceKey = 'capture_selected_interface';
  static const _consentGrantedKey = 'capture_consent_granted';

  CaptureCapabilityResult? get capabilityResult => _capabilityResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get consentGiven => _consentGiven;
  bool get consentGranted => _consentGranted;
  bool get setupCompleted => _setupCompleted;
  bool get setupPreferenceLoaded => _setupPreferenceLoaded;
  String? get selectedInterfaceId => _selectedInterfaceId;
  bool get isSetupValid {
    final result = _capabilityResult;
    if (!_setupCompleted ||
        !_consentGranted ||
        result == null ||
        !result.captureSupported) {
      return false;
    }
    final selected = _selectedInterfaceId ?? result.recommendedInterface;
    return selected != null &&
        result.interfaces.any((item) => item.id == selected);
  }

  CaptureCapabilityProvider() {
    _init();
  }

  Future<void> _init() async {
    final preferences = await SharedPreferences.getInstance();
    _setupCompleted = preferences.getBool(_setupCompletedKey) ?? false;
    _selectedInterfaceId = preferences.getString(_selectedInterfaceKey);
    _consentGranted = preferences.getBool(_consentGrantedKey) ?? false;
    _consentGiven = _consentGranted;
    _setupPreferenceLoaded = true;
    await fetchCapabilities();
  }

  void setConsentGiven(bool value) {
    _consentGiven = value;
    notifyListeners();
  }

  Future<void> fetchCapabilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await LocalAgentClient.getCapabilities();
      _capabilityResult = CaptureCapabilityResult.fromJson(data);
    } catch (e) {
      _error = 'Error fetching capabilities: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCapabilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await LocalAgentClient.refreshCapabilities();
      _capabilityResult = CaptureCapabilityResult.fromJson(data);
    } catch (e) {
      _error = 'Error refreshing capabilities: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> runProbe(String interfaceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await LocalAgentClient.runCaptureProbe(interfaceId);
      _capabilityResult = CaptureCapabilityResult.fromJson(data);
      final passed = _capabilityResult?.probeState == CaptureProbeState.passed;
      if (passed) {
        _setupCompleted = true;
        _consentGranted = _consentGiven;
        _selectedInterfaceId = interfaceId;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_setupCompletedKey, true);
        await preferences.setString(_selectedInterfaceKey, interfaceId);
        await preferences.setBool(_consentGrantedKey, _consentGranted);
      }
      return passed;
    } catch (e) {
      _error = 'Error running probe: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reconfigure() async {
    _setupCompleted = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_setupCompletedKey, false);
    notifyListeners();
  }

  Future<void> runDiagnostics() async {
    await refreshCapabilities();
  }

  Future<void> resetSetup() async {
    _setupCompleted = false;
    _consentGranted = false;
    _consentGiven = false;
    _selectedInterfaceId = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_setupCompletedKey);
    await preferences.remove(_consentGrantedKey);
    await preferences.remove(_selectedInterfaceKey);
    notifyListeners();
  }

  Future<bool> executeRemediation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await LocalAgentClient.executeRemediation();
      final success = data['success'] as bool? ?? false;
      if (data['capabilities'] != null) {
        _capabilityResult =
            CaptureCapabilityResult.fromJson(data['capabilities']);
      }
      return success;
    } catch (e) {
      _error = 'Error executing remediation: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
