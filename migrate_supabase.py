import re
import os

with open('lib/main.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add supabase import
if 'supabase_flutter' not in code:
    code = code.replace(
        "import 'package:firebase_core/firebase_core.dart';",
        "import 'package:firebase_core/firebase_core.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';"
    )

# 2. Add supabase init
if 'Supabase.initialize' not in code:
    init_str = '''
    try {
      await Supabase.initialize(
        url: 'https://whliroffubcqsalxdqfs.supabase.co',
        anonKey: 'sb_publishable_dWnrma0eBAfoHidi0zvTdQ_arcCmFEe',
      );
      print('Supabase Initialized');
    } catch(e) {
      print('Supabase Init Error: $e');
    }
'''
    code = code.replace(
        'print("Firebase Initialized Successfully");',
        'print("Firebase Initialized Successfully");' + init_str
    )

# 3. Modify SyncService for Supabase
if 'static final _supabase =' not in code:
    code = code.replace(
        'class SyncService {',
        '''class SyncService {
  static final _supabase = Supabase.instance.client;'''
    )

# 4. We need to disable Firebase sync for notices, complaints, menu and add Supabase
# I will just write a Dart script to do the complex logic replacement, since python regex might break it.
# Actually I'll create a new file `lib/supabase_service.dart` and inject it.

with open('lib/main.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print('Basic Supabase init injected.')
