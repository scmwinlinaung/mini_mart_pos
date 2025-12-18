import '../../core/services/database_service.dart';
import '../models/auth.dart';

class UserDatabaseService {
  final DatabaseService _databaseService;

  UserDatabaseService(this._databaseService);

  Future<List<User>> getAllUsers() async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT u.*, r.role_name FROM users u LEFT JOIN roles r ON u.role_id = r.role_id ORDER BY u.user_id',
    );

    return result.map((row) {
      final role = row[7] != null ? _parseRole(row[7] as String) : Role.cashier;
      return User(
        id: row[0] as int,
        username: row[1] as String,
        fullName: row[2] as String,
        email: row[3] as String? ?? '',
        password: '', // Not exposed for security
        role: role,
        isActive: row[5] as bool? ?? true,
        createdAt: DateTime.parse(row[6] as String),
      );
    }).toList();
  }

  Future<User?> getUserById(int userId) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT u.*, r.role_name FROM users u LEFT JOIN roles r ON u.role_id = r.role_id WHERE u.user_id = \$1',
      parameters: [userId],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final role = row[7] != null ? _parseRole(row[7] as String) : Role.cashier;

    return User(
      id: row[0] as int,
      username: row[1] as String,
      fullName: row[2] as String,
      email: row[3] as String? ?? '',
      password: '', // Not exposed for security
      role: role,
      isActive: row[5] as bool? ?? true,
      createdAt: DateTime.parse(row[6] as String),
    );
  }

  Future<User?> getUserByUsername(String username) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT u.*, r.role_name FROM users u LEFT JOIN roles r ON u.role_id = r.role_id WHERE u.username = \$1',
      parameters: [username],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final role = row[7] != null ? _parseRole(row[7] as String) : Role.cashier;

    return User(
      id: row[0] as int,
      username: row[1] as String,
      fullName: row[2] as String,
      email: row[3] as String? ?? '',
      password: '', // Not exposed for security
      role: role,
      isActive: row[5] as bool? ?? true,
      createdAt: DateTime.parse(row[6] as String),
    );
  }

  Future<int> createUser({
    required String username,
    required String fullName,
    required String password,
    required Role role,
    String? email,
    bool isActive = true,
  }) async {
    final conn = await _databaseService.connection;

    // First get role_id
    final roleResult = await conn.execute(
      'SELECT role_id FROM roles WHERE role_name = \$1',
      parameters: [role.name],
    );

    if (roleResult.isEmpty) {
      throw Exception('Role not found: ${role.name}');
    }

    final roleId = roleResult.first[0] as int;

    final result = await conn.execute(
      '''INSERT INTO users (username, full_name, password_hash, role_id, email, is_active, created_at)
         VALUES (\$1, \$2, \$3, \$4, \$5, \$6, NOW()) RETURNING user_id''',
      parameters: [username, fullName, password, roleId, email, isActive],
    );

    return result.first[0] as int;
  }

  Future<void> updateUser(
    int userId, {
    String? username,
    String? fullName,
    String? password,
    Role? role,
    String? email,
    bool? isActive,
  }) async {
    final conn = await _databaseService.connection;

    final updates = <String>[];
    final values = <dynamic>[];
    var paramIndex = 1;

    if (username != null) {
      updates.add('username = \$$paramIndex');
      values.add(username);
      paramIndex++;
    }

    if (fullName != null) {
      updates.add('full_name = \$$paramIndex');
      values.add(fullName);
      paramIndex++;
    }

    if (password != null) {
      updates.add('password_hash = \$$paramIndex');
      values.add(password);
      paramIndex++;
    }

    if (role != null) {
      updates.add(
        'role_id = (SELECT role_id FROM roles WHERE role_name = \$$paramIndex)',
      );
      values.add(role.name);
      paramIndex++;
    }

    if (email != null) {
      updates.add('email = \$$paramIndex');
      values.add(email);
      paramIndex++;
    }

    if (isActive != null) {
      updates.add('is_active = \$$paramIndex');
      values.add(isActive);
      paramIndex++;
    }

    if (updates.isEmpty) return;

    updates.add('updated_at = NOW()');
    values.add(userId);

    final query =
        'UPDATE users SET ${updates.join(', ')} WHERE user_id = \$$paramIndex';
    await conn.execute(query, parameters: values);
  }

  Future<void> deleteUser(int userId) async {
    final conn = await _databaseService.connection;
    await conn.execute(
      'DELETE FROM users WHERE user_id = \$1',
      parameters: [userId],
    );
  }

  Future<List<Role>> getAllRoles() async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT role_name FROM roles ORDER BY role_id',
    );

    return result.map((row) => _parseRole(row[0] as String)).toList();
  }

  Future<bool> usernameExists(String username) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      'SELECT COUNT(*) as count FROM users WHERE username = \$1',
      parameters: [username],
    );

    return (result.first[0] as int) > 0;
  }

  Role _parseRole(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
        return Role.admin;
      case 'manager':
        return Role.manager;
      case 'cashier':
        return Role.cashier;
      default:
        return Role.cashier;
    }
  }

  Future<User?> authenticateUser(String username, String password) async {
    final conn = await _databaseService.connection;
    final result = await conn.execute(
      '''SELECT u.*, r.role_name FROM users u
         LEFT JOIN roles r ON u.role_id = r.role_id
         WHERE u.username = \$1 AND u.password_hash = \$2 AND u.is_active = true''',
      parameters: [username, password],
    );

    if (result.isEmpty) return null;

    final row = result.first;
    final role = row[7] != null ? _parseRole(row[7] as String) : Role.cashier;

    // Update last login
    await conn.execute(
      'UPDATE users SET last_login = NOW() WHERE user_id = \$1',
      parameters: [row[0]],
    );

    return User(
      id: row[0] as int,
      username: row[1] as String,
      fullName: row[2] as String,
      email: row[3] as String? ?? '',
      password: '', // Not exposed for security
      role: role,
      isActive: row[5] as bool? ?? true,
      createdAt: DateTime.parse(row[6] as String),
    );
  }

  // Additional methods needed by repository
  Future<bool> deactivateUser(int userId) async {
    final conn = await _databaseService.connection;
    await conn.execute(
      'UPDATE users SET is_active = false WHERE user_id = \$1',
      parameters: [userId],
    );
    return true;
  }

  Future<bool> activateUser(int userId) async {
    final conn = await _databaseService.connection;
    await conn.execute(
      'UPDATE users SET is_active = true WHERE user_id = \$1',
      parameters: [userId],
    );
    return true;
  }
}
