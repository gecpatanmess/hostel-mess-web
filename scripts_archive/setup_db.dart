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

  // Create notices
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS notices (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        date TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  ''');
  print('Notices table created.');

  // Create complaints
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS complaints (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        student_name TEXT NOT NULL,
        student_room TEXT NOT NULL,
        date TIMESTAMPTZ NOT NULL DEFAULT now(),
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image_url TEXT,
        is_resolved BOOLEAN NOT NULL DEFAULT false
    );
  ''');
  print('Complaints table created.');

  // Create menu
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS menu (
        id INTEGER PRIMARY KEY,
        image_url TEXT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  ''');
  print('Menu table created.');

  // Bucket for mess_images
  try {
    await conn.execute('''
      INSERT INTO storage.buckets (id, name, public) 
      VALUES ('mess_images', 'mess_images', true)
      ON CONFLICT (id) DO NOTHING;
    ''');
    print('Storage bucket created.');
  } catch(e) {
    print('Storage bucket error: $e');
  }

  // RLS Policies
  try {
    await conn.execute('ALTER TABLE notices ENABLE ROW LEVEL SECURITY;');
    await conn.execute('ALTER TABLE complaints ENABLE ROW LEVEL SECURITY;');
    await conn.execute('ALTER TABLE menu ENABLE ROW LEVEL SECURITY;');

    await conn.execute('CREATE POLICY "Public notices are viewable by everyone." ON notices FOR SELECT USING (true);');
    await conn.execute('CREATE POLICY "Admins can insert notices" ON notices FOR INSERT WITH CHECK (true);');
    await conn.execute('CREATE POLICY "Admins can update notices" ON notices FOR UPDATE USING (true);');
    await conn.execute('CREATE POLICY "Admins can delete notices" ON notices FOR DELETE USING (true);');

    await conn.execute('CREATE POLICY "Public complaints are viewable by everyone." ON complaints FOR SELECT USING (true);');
    await conn.execute('CREATE POLICY "Anyone can insert complaints" ON complaints FOR INSERT WITH CHECK (true);');
    await conn.execute('CREATE POLICY "Admins can update complaints" ON complaints FOR UPDATE USING (true);');
    await conn.execute('CREATE POLICY "Admins can delete complaints" ON complaints FOR DELETE USING (true);');

    await conn.execute('CREATE POLICY "Public menu is viewable by everyone." ON menu FOR SELECT USING (true);');
    await conn.execute('CREATE POLICY "Admins can insert menu" ON menu FOR INSERT WITH CHECK (true);');
    await conn.execute('CREATE POLICY "Admins can update menu" ON menu FOR UPDATE USING (true);');
    await conn.execute('CREATE POLICY "Admins can delete menu" ON menu FOR DELETE USING (true);');

    await conn.execute('CREATE POLICY "Public storage view" ON storage.objects FOR SELECT USING (bucket_id = \'mess_images\');');
    await conn.execute('CREATE POLICY "Public storage insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = \'mess_images\');');
    await conn.execute('CREATE POLICY "Public storage update" ON storage.objects FOR UPDATE USING (bucket_id = \'mess_images\');');
    await conn.execute('CREATE POLICY "Public storage delete" ON storage.objects FOR DELETE USING (bucket_id = \'mess_images\');');
    print('RLS Policies created.');
  } catch(e) {
    print('Policies error: $e');
  }

  await conn.close();
}
