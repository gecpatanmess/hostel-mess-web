with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

import_stmt = "import 'update_service.dart';"
if import_stmt not in code:
    code = code.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'update_service.dart';")

# Replace `home: initialScreen ?? const LoginScreen(),`
home_wrapper = '''home: UpdateCheckerWrapper(child: initialScreen ?? const LoginScreen()),'''
code = code.replace('home: initialScreen ?? const LoginScreen(),', home_wrapper)

# Add UpdateCheckerWrapper class at the end
wrapper_class = '''

class UpdateCheckerWrapper extends StatefulWidget {
  final Widget child;
  const UpdateCheckerWrapper({super.key, required this.child});

  @override
  State<UpdateCheckerWrapper> createState() => _UpdateCheckerWrapperState();
}

class _UpdateCheckerWrapperState extends State<UpdateCheckerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppUpdateService.checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
'''
if 'class UpdateCheckerWrapper' not in code:
    code += wrapper_class

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("Update wrapper added")
