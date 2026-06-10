import 'package:flutter/material.dart';
import '../models/firewall_log.dart';

class FirewallLogsProvider extends ChangeNotifier {
  bool _autoFetch = true;
  
  bool get autoFetch => _autoFetch;
  
  final List<FirewallLog> _logs = [
    FirewallLog(
      id: '1',
      ip: '185.220.101.45',
      port: 22,
      action: FirewallAction.blocked,
      timestamp: '2026-04-12 14:23:45',
      rule: 'SSH-BRUTE-FORCE',
    ),
    FirewallLog(
      id: '2',
      ip: '103.56.207.23',
      port: 443,
      action: FirewallAction.allowed,
      timestamp: '2026-04-12 14:23:42',
      rule: 'HTTPS-ALLOW',
    ),
    FirewallLog(
      id: '3',
      ip: '45.142.120.67',
      port: 3389,
      action: FirewallAction.blocked,
      timestamp: '2026-04-12 14:23:38',
      rule: 'RDP-BLOCK',
    ),
    FirewallLog(
      id: '4',
      ip: '193.164.132.88',
      port: 80,
      action: FirewallAction.allowed,
      timestamp: '2026-04-12 14:23:35',
      rule: 'HTTP-ALLOW',
    ),
    FirewallLog(
      id: '5',
      ip: '89.248.167.131',
      port: 23,
      action: FirewallAction.blocked,
      timestamp: '2026-04-12 14:23:30',
      rule: 'TELNET-BLOCK',
    ),
    FirewallLog(
      id: '6',
      ip: '178.128.141.45',
      port: 443,
      action: FirewallAction.allowed,
      timestamp: '2026-04-12 14:23:28',
      rule: 'HTTPS-ALLOW',
    ),
    FirewallLog(
      id: '7',
      ip: '167.99.241.32',
      port: 1433,
      action: FirewallAction.blocked,
      timestamp: '2026-04-12 14:23:25',
      rule: 'SQL-BLOCK',
    ),
  ];
  
  List<FirewallLog> get logs => _logs;
  
  int get blockedCount =>
      _logs.where((log) => log.action == FirewallAction.blocked).length;
  
  int get allowedCount =>
      _logs.where((log) => log.action == FirewallAction.allowed).length;
  
  List<FirewallLog> get blockedLogs =>
      _logs.where((log) => log.action == FirewallAction.blocked).take(5).toList();
  
  void toggleAutoFetch() {
    _autoFetch = !_autoFetch;
    notifyListeners();
  }
}
