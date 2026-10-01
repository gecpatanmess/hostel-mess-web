import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'db.whliroffubcqsalxdqfs.supabase.co',
      database: 'postgres',
      username: 'postgres',
      password: 'vishal123@parmar',
      port: 5432,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('Connected to database!');

  // Create app_updates table
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS app_updates (
        id INTEGER PRIMARY KEY DEFAULT 1,
        version TEXT NOT NULL,
        apk_url TEXT NOT NULL,
        is_mandatory BOOLEAN NOT NULL DEFAULT false,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  ''');
  print('Table created.');

  // Insert initial row
  try {
    await conn.execute('''
      INSERT INTO app_updates (id, version, apk_url, is_mandatory) 
      VALUES (1, '1.0.0', 'https://github.com/your-username/your-repo/releases/download/v1.0.0/app-release.apk', false)
      ON CONFLICT (id) DO NOTHING;
    ''');
    print('Initial row inserted.');
  } catch(e) {
    print('Insert error: $e');
  }

  // RLS Policies
  try {
    await conn.execute('ALTER TABLE app_updates ENABLE ROW LEVEL SECURITY;');
    await conn.execute('CREATE POLICY "Public read app_updates" ON app_updates FOR SELECT USING (true);');
    await conn.execute('CREATE POLICY "Admins can update app_updates" ON app_updates FOR UPDATE USING (true);');
    await conn.execute('CREATE POLICY "Admins can insert app_updates" ON app_updates FOR INSERT WITH CHECK (true);');
  } catch(e) {}

  await conn.close();
}
