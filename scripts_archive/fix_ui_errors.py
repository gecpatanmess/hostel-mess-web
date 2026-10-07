import sys

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target_push = """    } catch(e) {
      print("Push menu error: $e");
    }"""
new_push = """    } catch(e) {
      print("Push menu error: $e");
      throw Exception("Supabase Upload Error: $e");
    }"""

if target_push in text:
    text = text.replace(target_push, new_push)
    print("SUCCESS: pushMenu now throws")
else:
    print("WARNING: pushMenu catch block not found")

# Now let's update the UI calls to pushMenu to catch and show the error.
# There are two calls: one for picking a file, one for deleting.

target_ui_pick = """                              await SyncService.pushMenu();
                            }
                          }
                        },"""
new_ui_pick = """                              try {
                                await SyncService.pushMenu();
                              } catch(e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                              }
                            }
                          }
                        },"""

if target_ui_pick in text:
    text = text.replace(target_ui_pick, new_ui_pick)
    print("SUCCESS: UI pick fixed")

target_ui_delete = """                                setState(() {});
                                await SyncService.pushMenu();
                              },"""
new_ui_delete = """                                setState(() {});
                                try {
                                  await SyncService.pushMenu();
                                } catch(e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                                }
                              },"""

if target_ui_delete in text:
    text = text.replace(target_ui_delete, new_ui_delete)
    print("SUCCESS: UI delete fixed")

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(text)
