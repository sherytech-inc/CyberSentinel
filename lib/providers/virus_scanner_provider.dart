import 'package:flutter/material.dart';
import '../models/scan_result.dart';

class VirusScannerProvider extends ChangeNotifier {
  String _url = '';
  bool _isScanning = false;
  ScanResult? _scanResult;
  
  String get url => _url;
  bool get isScanning => _isScanning;
  ScanResult? get scanResult => _scanResult;
  
  void setUrl(String value) {
    _url = value;
    notifyListeners();
  }
  
  Future<void> startScan() async {
    _isScanning = true;
    _scanResult = null;
    notifyListeners();
    
    // Simulate scanning
    await Future.delayed(const Duration(seconds: 2));
    
    _scanResult = ScanResult(
      fileName: 'sample_file.exe',
      threatLevel: ScanThreatLevel.high,
      enginesDetected: 34,
      totalEngines: 70,
      detections: [
        'Trojan.Generic.KD.12345',
        'Malware.AI.2876543',
        'Suspicious.Behavior.AB12',
      ],
    );
    
    _isScanning = false;
    notifyListeners();
  }
  
  void clearResults() {
    _scanResult = null;
    _url = '';
    notifyListeners();
  }
}
