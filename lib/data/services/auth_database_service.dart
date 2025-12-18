import 'package:postgres/postgres.dart';
import '../../core/services/database_service.dart';

class AuthDatabaseService {
  final DatabaseService _dbService;

  AuthDatabaseService(this._dbService);

  // Get user by username with role information
  Future<Map<String, dynamic>?> getUserWithRole(String username) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      SELECT
        u.user_id,
        u.username,
        u.password_hash,
        u.full_name,
        u.role_id,
        u.is_active,
        u.created_at,
        r.role_name
      FROM users u
      JOIN roles r ON u.role_id = r.role_id
      WHERE u.username = @username AND u.is_active = TRUE
    '''),
      parameters: {'username': username},
    );

    if (result.isEmpty) return null;
    return result.first.toColumnMap();
  }

  // Get all users with role information
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final conn = await _dbService.connection;
    final result = await conn.execute('''
      SELECT
        u.user_id,
        u.username,
        u.full_name,
        u.role_id,
        u.is_active,
        u.created_at,
        r.role_name
      FROM users u
      JOIN roles r ON u.role_id = r.role_id
      ORDER BY u.created_at DESC
    ''');

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Get all roles
  Future<List<Map<String, dynamic>>> getAllRoles() async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      'SELECT role_id, role_name FROM roles ORDER BY role_id',
    );

    return result.map((row) => row.toColumnMap()).toList();
  }

  // Create new user
  Future<int> createUser({
    required String username,
    required String passwordHash,
    required String fullName,
    required int roleId,
  }) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('''
      INSERT INTO users (username, password_hash, full_name, role_id, is_active)
      VALUES (@username, @password, @full_name, @role_id, TRUE)
      RETURNING user_id
    '''),
      parameters: {
        'username': username,
        'password': passwordHash,
        'full_name': fullName,
        'role_id': roleId,
      },
    );

    return result.first[0] as int;
  }

  // Update user
  Future<bool> updateUser(int userId, Map<String, dynamic> updates) async {
    final conn = await _dbService.connection;

    final setClause = updates.keys.map((key) => '$key = @$key').join(', ');
    updates['user_id'] = userId;

    final result = await conn.execute(
      Sql.named('''
      UPDATE users
      SET $setClause
      WHERE user_id = @user_id
    '''),
      parameters: updates,
    );

    return result.affectedRows > 0;
  }

  // Soft delete user (set is_active to false)
  Future<bool> deactivateUser(int userId) async {
    final conn = await _dbService.connection;
    final result = await conn.execute(
      Sql.named('UPDATE users SET is_active = FALSE WHERE user_id = @user_id'),
      parameters: {'user_id': userId},
    );

    return result.affectedRows > 0;
  }

  // Check if username exists
  Future<bool> usernameExists(String username, {int? excludeUserId}) async {
    final conn = await _dbService.connection;

    String sql = 'SELECT COUNT(*) FROM users WHERE username = @username';
    var params = <String, dynamic>{'username': username};

    if (excludeUserId != null) {
      sql += ' AND user_id != @exclude_id';
      params['exclude_id'] = excludeUserId;
    }

    final result = await conn.execute(Sql.named(sql), parameters: params);
    final count = result.first.first as int;
    return count > 0;
  }
}
