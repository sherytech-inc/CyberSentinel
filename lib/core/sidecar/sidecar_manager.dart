import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class SidecarManager {
  static final SidecarManager _instance = SidecarManager._internal();
  factory SidecarManager() => _instance;
  SidecarManager._internal();

  Process? _process;
  int? _port;
  String? _localToken;
  bool _isRunning = false;

  int? get port => _port;
  String? get localToken => _localToken;
  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;

    try {
      // 1. Find an available port
      final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _port = serverSocket.port;
      await serverSocket.close();

      // 2. Generate Local Token
      _localToken = const Uuid().v4();

      // 3. Resolve backend path (Assuming development environment layout)
      final currentDir = Directory.current.path;
      final backendPath = path.normalize(path.join(currentDir, '..', 'cybersentinel_api'));
      
      // Use the local python virtual environment
      final venvPython = path.join(backendPath, 'venv', 'bin', 'python');

      debugPrint('Starting sidecar from $venvPython on port $_port');

      // 4. Start process
      _process = await Process.start(
        venvPython,
        ['-m', 'uvicorn', 'app.main:app', '--port', _port.toString(), '--host', '127.0.0.1'],
        workingDirectory: backendPath,
        environment: {
          'CYBERSENTINEL_LOCAL_TOKEN': _localToken!,
        },
      );

      _isRunning = true;

      // 5. Handle output for debugging
      _process!.stdout.transform(utf8.decoder).listen((data) {
        // debugPrint('[SIDECAR STDOUT] $data');
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        // debugPrint('[SIDECAR STDERR] $data');
      });

      // 6. Wait for health check
      await _waitForHealth();
      debugPrint('Sidecar is up and healthy.');
    } catch (e) {
      debugPrint('Failed to start sidecar: $e');
      _isRunning = false;
      stop();
      rethrow;
    }
  }

  Future<void> _waitForHealth() async {
    final httpClient = HttpClient();
    int retries = 0;
    while (retries < 20) {
      try {
        final request = await httpClient.get('127.0.0.1', _port!, '/health');
        final response = await request.close();
        if (response.statusCode == 200) {
          httpClient.close();
          return;
        }
      } catch (e) {
        // ignore and retry
      }
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }
    httpClient.close();
    throw Exception('Failed to connect to sidecar on port $_port after multiple retries.');
  }

  void stop() {
    if (_process != null) {
      debugPrint('Stopping sidecar...');
      _process!.kill();
      _process = null;
    }
    _isRunning = false;
    _port = null;
    _localToken = null;
  }
}
