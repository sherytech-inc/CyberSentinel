import 'package:flutter/material.dart';
import '../models/ip_info.dart';

class IPAnalysisProvider extends ChangeNotifier {
  String _searchQuery = '';
  IPInfo? _ipInfo;
  
  String get searchQuery => _searchQuery;
  IPInfo? get ipInfo => _ipInfo;
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void analyzeIP() {
    _ipInfo = IPInfo(
      ip: '185.220.101.45',
      location: 'Moscow, Russia',
      country: 'RU',
      isp: 'Yandex LLC',
      reputation: 34,
      threatLevel: ThreatLevel.malicious,
    );
    notifyListeners();
  }
  
  void clearResults() {
    _ipInfo = null;
    _searchQuery = '';
    notifyListeners();
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
