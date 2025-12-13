import 'package:postgres/postgres.dart';

class DatabaseService {
  Connection? _connection;

  final Endpoint _endpoint = Endpoint(
    host: 'localhost',
    database: 'pos_db',
    username: 'postgres',
    password: 'password', // Update this
    port: 5432,
  );

  Future<Connection> get connection async {
    if (_connection != null && _connection!.isOpen) return _connection!;
    _connection = await Connection.open(_endpoint);
    return _connection!;
  }
}
