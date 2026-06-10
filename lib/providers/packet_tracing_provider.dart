import 'package:flutter/material.dart';
import '../models/packet.dart';

class PacketTracingProvider extends ChangeNotifier {
  bool _isCapturing = false;
  Packet? _selectedPacket;
  String _protocolFilter = 'all';
  String _riskFilter = 'all';
  
  bool get isCapturing => _isCapturing;
  Packet? get selectedPacket => _selectedPacket;
  String get protocolFilter => _protocolFilter;
  String get riskFilter => _riskFilter;
  
  final List<Packet> _packets = [
    Packet(
      id: '1',
      ip: '192.168.1.45',
      port: 443,
      protocol: 'HTTPS',
      size: '1.2 KB',
      status: PacketStatus.normal,
      timestamp: '14:23:45',
    ),
    Packet(
      id: '2',
      ip: '10.0.0.234',
      port: 22,
      protocol: 'SSH',
      size: '512 B',
      status: PacketStatus.suspicious,
      timestamp: '14:23:46',
    ),
    Packet(
      id: '3',
      ip: '172.16.0.88',
      port: 80,
      protocol: 'HTTP',
      size: '2.4 KB',
      status: PacketStatus.malicious,
      timestamp: '14:23:47',
    ),
    Packet(
      id: '4',
      ip: '192.168.0.156',
      port: 8080,
      protocol: 'HTTP',
      size: '3.1 KB',
      status: PacketStatus.normal,
      timestamp: '14:23:48',
    ),
    Packet(
      id: '5',
      ip: '10.1.1.23',
      port: 3306,
      protocol: 'MySQL',
      size: '768 B',
      status: PacketStatus.suspicious,
      timestamp: '14:23:49',
    ),
  ];
  
  List<Packet> get packets => _packets;
  
  void toggleCapturing() {
    _isCapturing = !_isCapturing;
    notifyListeners();
  }
  
  void selectPacket(Packet packet) {
    _selectedPacket = packet;
    notifyListeners();
  }
  
  void setProtocolFilter(String filter) {
    _protocolFilter = filter;
    notifyListeners();
  }
  
  void setRiskFilter(String filter) {
    _riskFilter = filter;
    notifyListeners();
  }
}
