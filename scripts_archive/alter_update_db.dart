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
    await conn.execute('''
      ALTER TABLE app_updates ADD COLUMN IF NOT EXISTS ios_url TEXT;
    ''');
    print('ios_url column added if missing.');
  } catch(e) {
    print('Error adding column: $e');
  }

  await conn.close();
}
