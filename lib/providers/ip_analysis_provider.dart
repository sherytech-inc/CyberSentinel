import 'package:flutter/material.dart';
import '../models/ip_info.dart';

class IPAnalysisProvider extends ChangeNotifier {
  String _searchQuery = '';
  IPInfo? _ipInfo;
  String? _errorMessage;

  String get searchQuery => _searchQuery;
  IPInfo? get ipInfo => _ipInfo;
  String? get errorMessage => _errorMessage;

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Clear any previous error when the user starts typing again
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Validates the entered IP address and returns mock analysis data for it.
  /// When the backend is ready, replace the mock block with an API call.
  void analyzeIP() {
    final query = _searchQuery.trim();

    // ── Validation ──────────────────────────────────────────────────────────
    if (query.isEmpty) {
      _errorMessage = 'Please enter an IP address.';
      _ipInfo = null;
      notifyListeners();
      return;
    }

    if (!_isValidIP(query)) {
      _errorMessage = '"$query" is not a valid IPv4 address.';
      _ipInfo = null;
      notifyListeners();
      return;
    }

    // ── Mock response using the actual entered IP ────────────────────────────
    // Replace this block with a real API call when backend is connected.
    _errorMessage = null;
    _ipInfo = _mockAnalysis(query);
    notifyListeners();
  }

  void clearResults() {
    _ipInfo = null;
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Basic IPv4 validation — four octets of 0-255 separated by dots.
  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final n = int.tryParse(part);
      if (n == null || n < 0 || n > 255) return false;
    }
    return true;
  }

  /// Returns deterministic mock data seeded by the entered IP so different
  /// IPs produce visibly different results before the real backend is wired up.
  IPInfo _mockAnalysis(String ip) {
    // Use the sum of octets to vary the mock output
    final octets = ip.split('.').map((o) => int.tryParse(o) ?? 0).toList();
    final seed = octets.fold(0, (sum, o) => sum + o);

    final locations = [
      'Moscow, Russia',
      'Beijing, China',
      'Frankfurt, Germany',
      'New York, USA',
      'Amsterdam, Netherlands',
      'London, UK',
    ];
    final isps = [
      'Yandex LLC',
      'China Telecom',
      'Deutsche Telekom',
      'Verizon Communications',
      'KPN B.V.',
      'British Telecom',
    ];
    final countries = ['RU', 'CN', 'DE', 'US', 'NL', 'GB'];
    final threatLevels = [
      ThreatLevel.malicious,
      ThreatLevel.malicious,
      ThreatLevel.suspicious,
      ThreatLevel.clean,
      ThreatLevel.suspicious,
      ThreatLevel.clean,
    ];

    final idx = seed % locations.length;
    // Reputation inversely related to threat level for realism
    final reputation = threatLevels[idx] == ThreatLevel.malicious
        ? 20 + (seed % 20)
        : threatLevels[idx] == ThreatLevel.suspicious
            ? 40 + (seed % 20)
            : 70 + (seed % 25);

    return IPInfo(
      ip: ip,
      location: locations[idx],
      country: countries[idx],
      isp: isps[idx],
      reputation: reputation.clamp(0, 100),
      threatLevel: threatLevels[idx],
    );
  }

  List<ActivityData> get activityData => [
        ActivityData(time: '00:00', requests: 45),
        ActivityData(time: '04:00', requests: 23),
        ActivityData(time: '08:00', requests: 89),
        ActivityData(time: '12:00', requests: 156),
        ActivityData(time: '16:00', requests: 234),
        ActivityData(time: '20:00', requests: 178),
      ];
}

class ActivityData {
  final String time;
  final int requests;

  ActivityData({required this.time, required this.requests});
}
