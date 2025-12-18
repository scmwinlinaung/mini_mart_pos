import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('🔍 Testing database connection...');

  final endpoint = Endpoint(
    host: 'localhost',
    database: 'mini_mart_pos',
    username: 'postgres',
    password: 'password',
    port: 5432,
  );

  try {
    final connection = await Connection.open(
      endpoint,
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    print('✅ Database connection successful!');

    // Test a simple query
    final result = await connection.execute('SELECT COUNT(*) FROM roles');
    final count = result.first.first as int;
    print('✅ Query successful! Found $count roles in the database.');

    // Test another query
    final productResult = await connection.execute('SELECT COUNT(*) FROM products');
    final productCount = productResult.first.first as int;
    print('✅ Found $productCount products in the database.');

    await connection.close();
    print('✅ Connection closed successfully.');

  } catch (e) {
    print('❌ Database connection failed: $e');
    exit(1);
  }
}