import 'package:flutter/material.dart';

import '../core/api/clients/local_agent_client.dart';
import '../models/scan_result.dart';
import 'session_cleanup_coordinator.dart';

typedef TextScanRequest = Future<Map<String, dynamic>> Function(String value);
typedef FileScanRequest = Future<Map<String, dynamic>> Function(
    String filename, List<int> bytes);

class VirusScannerProvider extends ChangeNotifier {
  VirusScannerProvider(
      {TextScanRequest? urlRequest,
      TextScanRequest? hashRequest,
      FileScanRequest? fileRequest})
      : _urlRequest = urlRequest ?? LocalAgentClient.scanVirusUrl,
        _hashRequest = hashRequest ?? LocalAgentClient.scanVirusHash,
        _fileRequest = fileRequest ?? LocalAgentClient.scanVirusFile {
    SessionCleanupCoordinator.registerCleanupTask(clear);
  }

  final TextScanRequest _urlRequest;
  final TextScanRequest _hashRequest;
  final FileScanRequest _fileRequest;
  String _urlInput = '';
  String _hashInput = '';
  String _fileInput = '';
  List<int>? _fileBytes;
  bool _urlScanning = false;
  bool _hashScanning = false;
  bool _fileScanning = false;
  ScanResult? _urlResult;
  ScanResult? _hashResult;
  ScanResult? _fileResult;
  String? _urlError;
  String? _hashError;
  String? _fileError;
  final List<ScanResult> _recentScans = [];

  String get urlInput => _urlInput;
  String get hashInput => _hashInput;
  String get fileInput => _fileInput;
  bool get hasSelectedFile => _fileBytes != null;
  bool get urlScanning => _urlScanning;
  bool get hashScanning => _hashScanning;
  bool get fileScanning => _fileScanning;
  ScanResult? get urlResult => _urlResult;
  ScanResult? get hashResult => _hashResult;
  ScanResult? get fileResult => _fileResult;
  String? get urlError => _urlError;
  String? get hashError => _hashError;
  String? get fileError => _fileError;
  int get selectedFileSize => _fileBytes?.length ?? 0;
  List<ScanResult> get recentScans => List.unmodifiable(_recentScans);
  String? get detectedHashType {
    final length = _hashInput.trim().length;
    if (!isValidHash(_hashInput)) return null;
    return length == 32
        ? 'MD5'
        : length == 40
            ? 'SHA-1'
            : 'SHA-256';
  }

  void setUrlInput(String value) {
    _urlInput = value;
    notifyListeners();
  }

  void setHashInput(String value) {
    _hashInput = value;
    notifyListeners();
  }

  void selectFile(String name, List<int> bytes) {
    _fileInput = name;
    _fileBytes = bytes;
    _fileResult = null;
    _fileError = null;
    notifyListeners();
  }

  void removeSelectedFile() {
    _fileInput = '';
    _fileBytes = null;
    _fileResult = null;
    _fileError = null;
    notifyListeners();
  }

  void clearUrlError() {
    _urlError = null;
    notifyListeners();
  }

  void clearHashError() {
    _hashError = null;
    notifyListeners();
  }

  void clearFileError() {
    _fileError = null;
    notifyListeners();
  }

  static bool isValidHash(String value) =>
      RegExp(r'^(?:[A-Fa-f0-9]{32}|[A-Fa-f0-9]{40}|[A-Fa-f0-9]{64})$')
          .hasMatch(value.trim());
  static bool isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<void> scanUrl() async {
    if (_urlScanning) return;
    if (!isValidUrl(_urlInput)) {
      _urlError = 'Enter a valid HTTP or HTTPS URL.';
      notifyListeners();
      return;
    }
    _urlScanning = true;
    _urlResult = null;
    _urlError = null;
    notifyListeners();
    try {
      _urlResult = await _parse(_urlRequest(_urlInput.trim()));
      _remember(_urlResult!);
    } catch (_) {
      _urlError = 'VirusTotal is temporarily unavailable.';
    } finally {
      _urlScanning = false;
      notifyListeners();
    }
  }

  Future<void> scanHash() async {
    if (_hashScanning) return;
    if (!isValidHash(_hashInput)) {
      _hashError = 'Enter a valid MD5, SHA-1, or SHA-256 hash.';
      notifyListeners();
      return;
    }
    _hashScanning = true;
    _hashResult = null;
    _hashError = null;
    notifyListeners();
    try {
      _hashResult = await _parse(_hashRequest(_hashInput.trim()));
      _remember(_hashResult!);
    } catch (_) {
      _hashError = 'VirusTotal is temporarily unavailable.';
    } finally {
      _hashScanning = false;
      notifyListeners();
    }
  }

  Future<void> scanSelectedFile() async {
    if (_fileScanning || _fileBytes == null) return;
    _fileScanning = true;
    _fileResult = null;
    _fileError = null;
    notifyListeners();
    try {
      _fileResult = await _parse(_fileRequest(_fileInput, _fileBytes!));
      _remember(_fileResult!);
    } catch (_) {
      _fileError = 'VirusTotal is temporarily unavailable.';
    } finally {
      _fileScanning = false;
      notifyListeners();
    }
  }

  Future<ScanResult> _parse(Future<Map<String, dynamic>> request) async {
    final result = await request;
    if (result['error'] == true) throw StateError('request_failed');
    return ScanResult.fromJson(result);
  }

  void _remember(ScanResult result) {
    _recentScans.removeWhere((item) =>
        item.scanType == result.scanType && item.target == result.target);
    _recentScans.insert(0, result);
    if (_recentScans.length > 8) _recentScans.removeLast();
  }

  void clear() {
    _urlInput = '';
    _hashInput = '';
    _fileInput = '';
    _fileBytes = null;
    _urlScanning = false;
    _hashScanning = false;
    _fileScanning = false;
    _urlResult = null;
    _hashResult = null;
    _fileResult = null;
    _urlError = null;
    _hashError = null;
    _fileError = null;
    _recentScans.clear();
    notifyListeners();
  }
}
