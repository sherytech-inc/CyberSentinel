import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  // Threat Score
  int _threatScore = 73;
  int get threatScore => _threatScore;
  
  // Traffic Data for Real-time Chart
  List<TrafficData> _trafficData = [];
  List<TrafficData> get trafficData => _trafficData;
  
  Timer? _trafficUpdateTimer;
  
  DashboardProvider() {
    _initializeTrafficData();
    _startTrafficUpdates();
  }
  
  void _initializeTrafficData() {
    final now = DateTime.now();
    for (int i = 23; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * 5));
      _trafficData.add(TrafficData(
        time: '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
        normal: Random().nextInt(3000) + 5000,
        suspicious: Random().nextInt(500) + 200,
        malicious: Random().nextInt(200) + 50,
      ));
    }
  }
  
  void _startTrafficUpdates() {
    _trafficUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateTrafficData();
    });
  }
  
  void _updateTrafficData() {
    _trafficData.removeAt(0);
    final now = DateTime.now();
    _trafficData.add(TrafficData(
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      normal: Random().nextInt(3000) + 5000,
      suspicious: Random().nextInt(500) + 200,
      malicious: Random().nextInt(200) + 50,
    ));
    notifyListeners();
  }
  
  // Alerts
  List<Alert> get alerts => [
    Alert(
      title: 'DDoS Attack Detected',
      description: 'Multiple connections from 185.220.101.45',
      time: '2 min ago',
      severity: AlertSeverity.high,
    ),
    Alert(
      title: 'Malware Detected',
      description: 'Trojan found in uploaded file',
      time: '5 min ago',
      severity: AlertSeverity.critical,
    ),
    Alert(
      title: 'Suspicious Login',
      description: 'Failed login attempts from unknown IP',
      time: '12 min ago',
      severity: AlertSeverity.medium,
    ),
  ];
  
  // Malicious IPs
  List<MaliciousIP> get maliciousIPs => [
    MaliciousIP(ip: '185.220.101.45', country: 'Russia', requests: 2847, threatLevel: 'Critical'),
    MaliciousIP(ip: '103.56.207.23', country: 'China', requests: 1923, threatLevel: 'High'),
    MaliciousIP(ip: '45.142.120.67', country: 'Ukraine', requests: 1456, threatLevel: 'High'),
    MaliciousIP(ip: '193.164.132.88', country: 'Netherlands', requests: 892, threatLevel: 'Medium'),
    MaliciousIP(ip: '89.248.167.131', country: 'Germany', requests: 734, threatLevel: 'Medium'),
  ];
  
  @override
  void dispose() {
    _trafficUpdateTimer?.cancel();
    super.dispose();
  }
}

class TrafficData {
  final String time;
  final int normal;
  final int suspicious;
  final int malicious;
  
  TrafficData({
    required this.time,
    required this.normal,
    required this.suspicious,
    required this.malicious,
  });
}

class Alert {
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;
  
  Alert({
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
  });
}

enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

class MaliciousIP {
  final String ip;
  final String country;
  final int requests;
  final String threatLevel;
  
  MaliciousIP({
    required this.ip,
    required this.country,
    required this.requests,
    required this.threatLevel,
  });
}
