import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RefreshInterval { off, seconds15, seconds30, seconds60 }

extension RefreshIntervalDuration on RefreshInterval {
  Duration? get duration {
    switch (this) {
      case RefreshInterval.off:
        return null;
      case RefreshInterval.seconds15:
        return const Duration(seconds: 15);
      case RefreshInterval.seconds30:
        return const Duration(seconds: 30);
      case RefreshInterval.seconds60:
        return const Duration(seconds: 60);
    }
  }

  String get label {
    switch (this) {
      case RefreshInterval.off:
        return 'Off';
      case RefreshInterval.seconds15:
        return '15 seconds';
      case RefreshInterval.seconds30:
        return '30 seconds';
      case RefreshInterval.seconds60:
        return '60 seconds';
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  RefreshInterval _refreshInterval = RefreshInterval.seconds30;

  ThemeMode get themeMode => _themeMode;
  RefreshInterval get refreshInterval => _refreshInterval;

  SettingsProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeIndex = prefs.getInt('themeMode');
      if (themeIndex != null &&
          themeIndex >= 0 &&
          themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }

      final intervalIndex = prefs.getInt('refreshInterval');
      if (intervalIndex != null &&
          intervalIndex >= 0 &&
          intervalIndex < RefreshInterval.values.length) {
        _refreshInterval = RefreshInterval.values[intervalIndex];
      }

      // Explicitly scrub any legacy secrets that might have been stored
      await _scrubLegacySecrets(prefs);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _scrubLegacySecrets(SharedPreferences prefs) async {
    final keysToScrub = [
      'virusTotalApiKey',
      'virustotal_api_key',
      'geoIPApiKey',
      'abuseIPDBApiKey',
      'abuseipdb_api_key',
      'groqApiKey',
      'groq_api_key',
      'supabase_service_role_key',
    ];
    for (final key in keysToScrub) {
      if (prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setRefreshInterval(RefreshInterval interval) {
    _refreshInterval = interval;
    notifyListeners();
  }

  Future<bool> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _scrubLegacySecrets(prefs);

      final results = await Future.wait([
        prefs.setInt('themeMode', _themeMode.index),
        prefs.setInt('refreshInterval', _refreshInterval.index),
      ]);

      return results.every((success) => success);
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}
