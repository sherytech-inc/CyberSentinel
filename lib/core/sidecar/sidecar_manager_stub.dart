/// Web stub for SidecarManager — dart:io (Process, ServerSocket) is unavailable on web.
/// On web, the FastAPI backend is expected to be running independently.

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

  int? get port => null;
  String? get localToken => null;
  bool get isRunning => false;
  int? get processId => null;
  String get stderrTail => '';

  Future<void> start() async {
    // No-op on web — sidecar process cannot be launched from a browser.
  }

  Future<void> stop({Duration timeout = const Duration(seconds: 2)}) async {
    // No-op on web.
  }
}
