import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../app_environment.dart';

class SidecarException implements Exception {
  final String code;
  final String message;
  SidecarException(this.code, this.message);

  @override
  String toString() => 'SidecarException: $code - $message';
}

class SidecarManager {
  static final SidecarManager _instance = SidecarManager._internal();
  factory SidecarManager() => _instance;
  SidecarManager._internal();

  Process? _process;
  int? _port;
  String? _localToken;
  bool _isRunning = false;
  String _stderrTail = '';

  int? get port => _port;
  String? get localToken => _localToken;
  bool get isRunning => _isRunning;
  int? get processId => _process?.pid;
  String get stderrTail => _stderrTail;

  Future<void> start() async {
    if (_isRunning || _process != null) return;

    try {
      const mode = AppEnvironment.desktopBackendMode;

      if (mode == 'external') {
        debugPrint(
            'Sidecar configured as external. Not starting a child process.');
        // Expecting external backend to be provided or default API_BASE_URL to be used.
        return;
      }

      // 1. Find an available port
      final serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      _port = serverSocket.port;
      await serverSocket.close();

      // 2. Generate Local Token
      _localToken = const Uuid().v4();

      final inheritedPath = Platform.environment['PATH'] ?? '/usr/bin:/bin';
      final environment = {
        'CYBERSENTINEL_LOCAL_TOKEN': _localToken!,
        'CYBERSENTINEL_PARENT_PID': pid.toString(),
        'PATH': '/opt/homebrew/bin:/usr/local/bin:$inheritedPath',
      };

      if (mode == 'managed_source') {
        const pythonPath = AppEnvironment.desktopBackendPython;
        const workdir = AppEnvironment.desktopBackendWorkdir;

        if (pythonPath.isEmpty) {
          throw SidecarException('backend_development_runtime_missing',
              'DESKTOP_BACKEND_PYTHON is not configured.');
        }
        if (workdir.isEmpty) {
          throw SidecarException('backend_development_runtime_missing',
              'DESKTOP_BACKEND_WORKDIR is not configured.');
        }

        final pythonFile = File(pythonPath);
        if (!pythonFile.existsSync()) {
          throw SidecarException('backend_development_runtime_missing',
              'Python executable not found at: $pythonPath');
        }

        final workdirDirectory = Directory(workdir);
        if (!workdirDirectory.existsSync()) {
          throw SidecarException('backend_development_runtime_missing',
              'Working directory not found at: $workdir');
        }

        debugPrint('Starting sidecar in managed_source mode on port $_port');

        _process = await Process.start(
          pythonPath,
          [
            '-m',
            'uvicorn',
            'app.main:app',
            '--host',
            '127.0.0.1',
            '--port',
            _port.toString()
          ],
          workingDirectory: workdir,
          environment: environment,
          mode: ProcessStartMode.normal,
          runInShell: false,
        );
      } else if (mode == 'bundled') {
        // Platform.resolvedExecutable is e.g. .../CyberSentinel.app/Contents/MacOS/CyberSentinel
        // Resources is a sibling of MacOS inside Contents.
        final executableUri = Uri.file(Platform.resolvedExecutable);
        final contentsDir = executableUri.resolve('../..').toFilePath();
        final bundledExecutablePath =
            '$contentsDir/Resources/${AppEnvironment.bundledBackendRelativePath}';

        final bundledFile = File(bundledExecutablePath);
        if (!bundledFile.existsSync()) {
          throw SidecarException('bundled_backend_missing',
              'Bundled backend executable not found.');
        }

        debugPrint('Starting sidecar in bundled mode on port $_port');

        _process = await Process.start(
          bundledExecutablePath,
          ['--host', '127.0.0.1', '--port', _port.toString()],
          environment: environment,
          mode: ProcessStartMode.normal,
          runInShell: false,
        );
      } else {
        throw SidecarException(
            'invalid_backend_mode', 'Unknown DESKTOP_BACKEND_MODE: $mode');
      }

      _isRunning = true;

      // 5. Handle output without blocking (drain stdout/stderr silently or log securely)
      final managedProcess = _process!;
      managedProcess.stdout.transform(utf8.decoder).listen((data) {
        // Drop stdout or debugPrint safely
      });

      managedProcess.stderr.transform(utf8.decoder).listen((data) {
        final token = _localToken;
        final safeData = token == null || token.isEmpty
            ? data
            : data.replaceAll(token, '[redacted]');
        _stderrTail = '$_stderrTail$safeData';
        if (_stderrTail.length > 8192) {
          _stderrTail = _stderrTail.substring(_stderrTail.length - 8192);
        }
        if (kDebugMode) debugPrint(safeData.trimRight());
      });

      // Handle early exit
      managedProcess.exitCode.then((code) {
        debugPrint('Sidecar process exited with code $code');
        if (identical(_process, managedProcess)) {
          _process = null;
          _isRunning = false;
        }
      });

      // 6. Wait for health check
      await _waitForHealth();
      debugPrint('Sidecar is up and healthy.');
    } catch (e) {
      if (e is SidecarException) {
        debugPrint('Sidecar failed: ${e.code}');
      } else {
        // In debug, log the error type (not message which may contain paths)
        debugPrint('Sidecar failed: ${e.runtimeType}');
      }
      _isRunning = false;
      await stop();
      rethrow;
    }
  }

  Future<void> _waitForHealth() async {
    final httpClient = HttpClient();
    int retries = 0;
    while (retries < 20) {
      if (!_isRunning && _process == null) {
        httpClient.close();
        throw SidecarException('sidecar_process_exited',
            'Sidecar process exited before becoming ready.');
      }
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
    throw SidecarException('sidecar_timeout',
        'Failed to connect to sidecar on loopback port after multiple retries.');
  }

  Future<void> stop({Duration timeout = const Duration(seconds: 2)}) async {
    final managedProcess = _process;
    if (managedProcess == null) return;

    debugPrint(
        'Stopping managed sidecar PID ${managedProcess.pid} gracefully...');
    managedProcess.kill(ProcessSignal.sigterm);
    try {
      await managedProcess.exitCode.timeout(timeout);
    } on TimeoutException {
      debugPrint(
          'Managed sidecar did not exit in time; force-killing PID ${managedProcess.pid}.');
      managedProcess.kill(ProcessSignal.sigkill);
      await managedProcess.exitCode.timeout(
        const Duration(seconds: 1),
        onTimeout: () => -1,
      );
    } finally {
      if (identical(_process, managedProcess)) {
        _process = null;
      }
    }
    _isRunning = false;
    _port = null;
    _localToken = null;
  }
}
