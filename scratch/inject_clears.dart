import 'dart:io';

void main() {
  final dir = Directory('lib/providers');
  final files = dir.listSync().whereType<File>();

  for (final file in files) {
    if (!file.path.endsWith('_provider.dart') || file.path.endsWith('auth_provider.dart')) continue;
    
    var content = file.readAsStringSync();
    
    if (!content.contains('session_cleanup_coordinator.dart')) {
      content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'session_cleanup_coordinator.dart';");
      if (!content.contains('session_cleanup_coordinator.dart')) {
        content = "import 'session_cleanup_coordinator.dart';\n$content";
      }
    }
    
    final classNameMatch = RegExp(r'class\s+(\w+)\s+extends\s+ChangeNotifier\s*\{').firstMatch(content);
    if (classNameMatch == null) continue;
    
    final className = classNameMatch.group(1);
    final constructorRegex = RegExp(r'(' + className! + r'\s*\([^)]*\)\s*(?::\s*super\([^)]*\)\s*)?\{)');
    
    if (constructorRegex.hasMatch(content)) {
      content = content.replaceFirstMapped(constructorRegex, (match) {
        return '${match.group(1)}\n    SessionCleanupCoordinator.registerCleanupTask(clear);';
      });
    } else {
      content = content.replaceFirst(
        RegExp(r'(class\s+' + className + r'\s+extends\s+ChangeNotifier\s*\{)'),
        '\$1\n  $className() {\n    SessionCleanupCoordinator.registerCleanupTask(clear);\n  }\n'
      );
    }
    
    if (!content.contains('void clear()')) {
      final lastBrace = content.lastIndexOf('}');
      if (lastBrace != -1) {
        content = content.substring(0, lastBrace) + '\n  void clear() {\n    // Add specific clear logic here\n    notifyListeners();\n  }\n' + content.substring(lastBrace);
      }
    }
    
    file.writeAsStringSync(content);
  }
  print('Done.');
}
