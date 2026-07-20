import 'package:cybersentinel/core/api/clients/cloud_control_plane_client.dart';
import 'package:cybersentinel/core/api/clients/local_agent_client.dart';
import 'package:flutter/material.dart';
import 'session_cleanup_coordinator.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';

class VirusScannerProvider extends ChangeNotifier {
  VirusScannerProvider() {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  String _url = '';
  bool _isScanning = false;
  ScanResult? _scanResult;
  String? _error;
  
  String get url => _url;
  bool get isScanning => _isScanning;
  ScanResult? get scanResult => _scanResult;
  String? get error => _error;
  
  void setUrl(String value) {
    _url = value;
    notifyListeners();
  }
  
  Future<void> startScan({String? fileName}) async {
    _isScanning = true;
    _scanResult = null;
    _error = null;
    notifyListeners();
    
    try {
      final String target = fileName ?? _url;
      final String type = fileName != null ? 'file' : 'url';
      
      final result = await CloudControlPlaneClient.scanVirus(target, type);
      
      if (result.containsKey('status') || result.containsKey('scan_type')) {
        _scanResult = ScanResult.fromJson(result);
      } else if (result.containsKey('error') && result['error'] == true) {
        _error = result['message'] as String? ?? 'Failed to perform virus scan';
      } else {
        _scanResult = ScanResult.fromJson(result);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> startFileScan(String fileName, List<int> bytes) async {
    _isScanning = true;
    _scanResult = null;
    _error = null;
    _url = fileName;
    notifyListeners();
    
    try {
      final result = await LocalAgentClient.scanVirusFile(fileName, bytes);
      
      if (result.containsKey('status') || result.containsKey('scan_type')) {
        _scanResult = ScanResult.fromJson(result);
      } else if (result.containsKey('error') && result['error'] == true) {
        _error = result['message'] as String? ?? 'Failed to perform virus scan';
      } else {
        _scanResult = ScanResult.fromJson(result);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
  
  void clearResults() {
    _scanResult = null;
    _url = '';
    _error = null;
    notifyListeners();
  }

  void clear() {
    clearResults();
  }
}
