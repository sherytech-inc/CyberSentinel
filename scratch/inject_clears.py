import os
import re

providers_dir = '/Users/shehrozali/cybersentinel/lib/providers'

for filename in os.listdir(providers_dir):
    if not filename.endswith('_provider.dart') or filename == 'auth_provider.dart':
        continue
    filepath = os.path.join(providers_dir, filename)
    with open(filepath, 'r') as f:
        content = f.read()

    # Find the class name
    class_match = re.search(r'class\s+(\w+)\s+extends\s+ChangeNotifier\s*\{', content)
    if not class_match:
        continue
    class_name = class_match.group(1)

    # Check if we already imported session_cleanup_coordinator
    if 'session_cleanup_coordinator.dart' not in content:
        # Add import at the top
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'session_cleanup_coordinator.dart';")
        if "import 'session_cleanup_coordinator.dart';" not in content:
            # fallback
            content = "import 'session_cleanup_coordinator.dart';\n" + content

    # Add constructor if not exists, or modify existing
    constructor_regex = r'(' + class_name + r'\s*\([^)]*\)\s*(?::\s*super\([^)]*\)\s*)?\{)'
    if re.search(constructor_regex, content):
        content = re.sub(
            constructor_regex,
            r'\1\n    SessionCleanupCoordinator.registerCleanupTask(clear);',
            content
        )
    else:
        # Inject constructor right after class declaration
        content = re.sub(
            r'(class\s+' + class_name + r'\s+extends\s+ChangeNotifier\s*\{)',
            r'\1\n  ' + class_name + r'() {\n    SessionCleanupCoordinator.registerCleanupTask(clear);\n  }\n',
            content
        )

    # Add clear method at the end of the class before the last '}'
    if 'void clear()' not in content:
        clear_method = """
  void clear() {
    // Add specific clear logic here
    notifyListeners();
  }
}"""
        # Find last '}'
        last_brace_index = content.rfind('}')
        if last_brace_index != -1:
            content = content[:last_brace_index] + clear_method + content[last_brace_index+1:]

    with open(filepath, 'w') as f:
        f.write(content)

print("Injected clear() and Coordinator hooks into providers.")
