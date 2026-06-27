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

  /// Returns the filtered packet list based on active protocol and risk filters.
  List<Packet> get packets {
    return _packets.where((packet) {
      // --- Protocol filter ---
      // Dropdown values are lowercase ('http', 'ssh', 'ftp', 'dns').
      // Packet protocols are mixed case ('HTTP', 'HTTPS', 'SSH', 'MySQL').
      // We treat 'http' as matching both HTTP and HTTPS.
      final bool protocolMatch = () {
        if (_protocolFilter == 'all') return true;
        if (_protocolFilter == 'http') {
          return packet.protocol.toUpperCase() == 'HTTP' ||
              packet.protocol.toUpperCase() == 'HTTPS';
        }
        return packet.protocol.toLowerCase() == _protocolFilter.toLowerCase();
      }();

      // --- Risk filter ---
      final bool riskMatch = () {
        if (_riskFilter == 'all') return true;
        switch (_riskFilter) {
          case 'normal':
            return packet.status == PacketStatus.normal;
          case 'suspicious':
            return packet.status == PacketStatus.suspicious;
          case 'malicious':
            return packet.status == PacketStatus.malicious;
          default:
            return true;
        }
      }();

      return protocolMatch && riskMatch;
    }).toList();
  }

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
    // Clear selected packet if it no longer appears in the filtered list
    if (_selectedPacket != null &&
        !packets.any((p) => p.id == _selectedPacket!.id)) {
      _selectedPacket = null;
    }
    notifyListeners();
  }

  void setRiskFilter(String filter) {
    _riskFilter = filter;
    // Clear selected packet if it no longer appears in the filtered list
    if (_selectedPacket != null &&
        !packets.any((p) => p.id == _selectedPacket!.id)) {
      _selectedPacket = null;
    }
    notifyListeners();
  }
}
