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

  try {
    await conn.execute('DROP TABLE IF EXISTS notices CASCADE;');
    await conn.execute('''
      CREATE TABLE notices (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          date TIMESTAMPTZ NOT NULL DEFAULT now()
      );
    ''');
    print('Notices table recreated.');
  } catch(e) {
    print('Notices error: $e');
  }

  try {
    await conn.execute('DROP TABLE IF EXISTS complaints CASCADE;');
    await conn.execute('''
      CREATE TABLE complaints (
          id TEXT PRIMARY KEY,
          student_name TEXT NOT NULL,
          student_room TEXT NOT NULL,
          date TIMESTAMPTZ NOT NULL DEFAULT now(),
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          image_url TEXT,
          is_resolved BOOLEAN NOT NULL DEFAULT false
      );
    ''');
    print('Complaints table recreated.');
  } catch(e) {
    print('Complaints error: $e');
  }

  // Re-apply RLS Policies
  try {
    await conn.execute('ALTER TABLE notices ENABLE ROW LEVEL SECURITY;');
    await conn.execute('ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;');

    await conn.execute('CREATE POLICY "Public notices view" ON notices FOR SELECT USING (true);');
    await conn.execute('CREATE POLICY "Admins notice insert" ON notices FOR INSERT WITH CHECK (true);');
    await conn.execute('CREATE POLICY "Admins notice update" ON notices FOR UPDATE USING (true);');
    await conn.execute('CREATE POLICY "Admins notice delete" ON notices FOR DELETE USING (true);');

    await conn.execute('CREATE POLICY "Public complaints view" ON complaints FOR SELECT USING (true);');
    await conn.execute('CREATE POLICY "Anyone complaint insert" ON complaints FOR INSERT WITH CHECK (true);');
    await conn.execute('CREATE POLICY "Anyone complaint update" ON complaints FOR UPDATE USING (true);');
    await conn.execute('CREATE POLICY "Anyone complaint delete" ON complaints FOR DELETE USING (true);');
    print('RLS Policies applied successfully.');
  } catch(e) {
    print('Policy error: $e');
  }

  await conn.close();
}
