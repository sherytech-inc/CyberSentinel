import 'package:flutter/material.dart';

/// Tracks the currently active navigation route across the app.
///
/// [MainLayout] calls [setCurrentRoute] whenever the user taps a nav item
/// or GoRouter reports a route change via [GoRouterState].
/// Any widget depending on [currentRoute] or [pageTitle] rebuilds automatically.
class AppStateProvider extends ChangeNotifier {
  // Must match the GoRouter initial route '/' not '/dashboard'
  String _currentRoute = '/';

  String get currentRoute => _currentRoute;

  /// Maps every registered GoRouter path to a human-readable page title.
  static const Map<String, String> _routeTitles = {
    '/': 'Dashboard',
    '/packet-tracing': 'Packet Tracing',
    '/firewall-logs': 'Firewall Logs',
    '/virus-scanner': 'Virus Scanner',
    '/ip-analysis': 'IP Analysis',
    '/reports': 'Reports',
    '/settings': 'Settings',
  };

  String get pageTitle => _routeTitles[_currentRoute] ?? _currentRoute;

  /// Updates the active route and notifies all listeners.
  /// No-ops if already on the same route to avoid unnecessary rebuilds.
  void setCurrentRoute(String route) {
    if (_currentRoute == route) return;
    _currentRoute = route;
    notifyListeners();
  }
}
