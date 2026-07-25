// Platform-agnostic interface for the sidecar process manager.
// Import this file — it routes to the correct implementation via conditional imports.
export 'sidecar_manager_stub.dart' if (dart.library.io) 'sidecar_manager.dart';
