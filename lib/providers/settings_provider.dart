import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _darkMode = true;
  bool _backgroundMonitoring = true;
  bool _emailAlerts = true;
  bool _pushAlerts = false;
  
  String _virusTotalApiKey = '';
  String _geoIPApiKey = '';
  String _abuseIPDBApiKey = '';
  
  // Getters
  bool get darkMode => _darkMode;
  bool get backgroundMonitoring => _backgroundMonitoring;
  bool get emailAlerts => _emailAlerts;
  bool get pushAlerts => _pushAlerts;
  
  String get virusTotalApiKey => _virusTotalApiKey;
  String get geoIPApiKey => _geoIPApiKey;
  String get abuseIPDBApiKey => _abuseIPDBApiKey;
  
  // Setters
  void setDarkMode(bool value) {
    _darkMode = value;
    notifyListeners();
  }
  
  void toggleBackgroundMonitoring() {
    _backgroundMonitoring = !_backgroundMonitoring;
    notifyListeners();
  }
  
  void toggleEmailAlerts() {
    _emailAlerts = !_emailAlerts;
    notifyListeners();
  }
  
  void togglePushAlerts() {
    _pushAlerts = !_pushAlerts;
    notifyListeners();
  }
  
  void setVirusTotalApiKey(String value) {
    _virusTotalApiKey = value;
    notifyListeners();
  }
  
  void setGeoIPApiKey(String value) {
    _geoIPApiKey = value;
    notifyListeners();
  }
  
  void setAbuseIPDBApiKey(String value) {
    _abuseIPDBApiKey = value;
    notifyListeners();
  }
  
  void saveSettings() {
    // In a real app, save to persistent storage
    // For now, just show a success message
    notifyListeners();
  }
}
