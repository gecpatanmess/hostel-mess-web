import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_dialog = '''      bool resetDone = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Reset Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(16)],
                decoration: const InputDecoration(hintText: "Enter new password (8-16 chars)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: rePassCtrl,
                inputFormatters: [LengthLimitingTextInputFormatter(16)],
                decoration: const InputDecoration(hintText: "Re-enter password"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (newPassCtrl.text.length != 8) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Password must be exactly 8 characters")));
                  return;
                }
                if (newPassCtrl.text != rePassCtrl.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text("Save"),
            )
          ],
        )
      ) ?? false;'''

new_dialog = '''      bool isForgotPinVisible = false;
      bool isForgotRePinVisible = false;
      bool resetDone = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: brandInputBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold, color: brandDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("New Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: newPassCtrl,
                      obscureText: !isForgotPinVisible,
                      maxLength: 16,
                      onChanged: (val) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: "Create password (8-16 chars)",
                        prefixIcon: const Icon(Icons.lock_outline, color: brandGray, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(isForgotPinVisible ? Icons.visibility : Icons.visibility_off, color: brandGray, size: 20),
                          onPressed: () => setStateDialog(() => isForgotPinVisible = !isForgotPinVisible),
                        ),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildPasswordHints(newPassCtrl.text),
                    const SizedBox(height: 16),
                    const Text("Confirm Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: brandDark)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: rePassCtrl,
                      obscureText: !isForgotRePinVisible,
                      maxLength: 16,
                      onChanged: (val) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: "Re-enter password",
                        prefixIcon: const Icon(Icons.lock_outline, color: brandGray, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(isForgotRePinVisible ? Icons.visibility : Icons.visibility_off, color: brandGray, size: 20),
                          onPressed: () => setStateDialog(() => isForgotRePinVisible = !isForgotRePinVisible),
                        ),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        counterText: "",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: brandGray))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    String? validationError = _validatePassword(newPassCtrl.text);
                    if (validationError != null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(validationError)));
                      return;
                    }
                    if (newPassCtrl.text != rePassCtrl.text) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text("Save"),
                )
              ],
            );
          }
        )
      ) ?? false;'''

if old_dialog in text:
    text = text.replace(old_dialog, new_dialog)
    with open('lib/main.dart', 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS: Dialog replaced!")
else:
    print("FAILED: Old dialog not found.")

