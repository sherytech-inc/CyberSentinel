import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  String _currentRoute = '/';
  
  String get currentRoute => _currentRoute;
  
  void setCurrentRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }
  
  String getPageTitle() {
    switch (_currentRoute) {
      case '/':
        return 'Dashboard';
      case '/packet-tracing':
        return 'Packet Tracing';
      case '/firewall-logs':
        return 'Firewall Logs';
      case '/virus-scanner':
        return 'Virus Scanner';
      case '/ip-analysis':
        return 'IP Analysis';
      case '/reports':
        return 'Reports';
      case '/settings':
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }
}
