import 'package:flutter/foundation.dart';

class SessionCleanupCoordinator {
  static final List<Function()> _cleanupTasks = [];

  static void registerCleanupTask(Function() task) {
    if (!_cleanupTasks.contains(task)) {
      _cleanupTasks.add(task);
    }
  }

  static void performCleanup() {
    if (kDebugMode) {
      print('SessionCleanupCoordinator: performing full state cleanup.');
    }
    for (var task in _cleanupTasks) {
      try {
        task();
      } catch (e) {
        if (kDebugMode) {
          print('Error during cleanup task: $e');
        }
      }
    }
  }
}
