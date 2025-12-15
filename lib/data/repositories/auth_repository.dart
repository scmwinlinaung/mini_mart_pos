import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';
import '../database_service.dart';
import 'package:mini_mart_pos/data/models/auth.dart';

class AuthRepository {
  final DatabaseService _databaseService = DatabaseService();

  // Hash password using SHA-256 (in production, use bcrypt or argon2)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify password
  bool _verifyPassword(String plainPassword, String hashedPassword) {
    final hashedInput = _hashPassword(plainPassword);
    return hashedInput == hashedPassword;
  }

  // Authenticate user
  Future<LoginResponse> authenticate(String username, String password) async {
    try {
      final conn = await _databaseService.connection;

      // Query user with role information
      final result = await conn.execute(Sql.named('''
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
      '''), parameters: {'username': username});

      if (result.isEmpty) {
        return LoginResponse.error('Invalid username or password');
      }

      final userRow = result.first;
      final storedHash = userRow[2] as String;

      // For demo purposes, check both hashed and plain passwords
      bool isValid = false;
      if (storedHash == 'hashed_admin_password' && password == 'admin123') {
        isValid = true;
      } else if (storedHash == 'hashed_cashier_password' && password == 'cashier123') {
        isValid = true;
      } else {
        isValid = _verifyPassword(password, storedHash);
      }

      if (!isValid) {
        return LoginResponse.error('Invalid username or password');
      }

      final user = User(
        userId: userRow[0] as int,
        username: userRow[1] as String,
        fullName: userRow[3] as String? ?? '',
        roleId: userRow[4] as int,
        roleName: userRow[8] as String?,
        isActive: userRow[5] as bool,
        createdAt: DateTime.parse(userRow[6] as String),
      );

      // Save session to shared preferences
      await _saveUserSession(user);

      return LoginResponse.success(user);
    } catch (e) {
      return LoginResponse.error('Authentication failed: ${e.toString()}');
    }
  }

  // Save user session to local storage
  Future<void> _saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final session = UserSession(
      user: user,
      loginTime: DateTime.now(),
      authToken: _generateAuthToken(),
    );

    await prefs.setString('user_session', jsonEncode(session.toMap()));
    await prefs.setBool('is_logged_in', true);
  }

  // Generate simple auth token (in production, use JWT)
  String _generateAuthToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = Uint8List.fromList(List.generate(16, (_) => timestamp % 256));
    return base64Encode(randomBytes);
  }

  // Get current user session
  Future<UserSession?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString('user_session');

      if (sessionData == null) return null;

      final sessionMap = jsonDecode(sessionData) as Map<String, dynamic>;
      return UserSession.fromMap(sessionMap);
    } catch (e) {
      print('Error getting current session: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final session = await getCurrentSession();
    return session != null;
  }

  // Logout user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Get all users (for admin user management)
  Future<List<User>> getAllUsers() async {
    try {
      final conn = await _databaseService.connection;

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

      return result.map((row) {
        return User(
          userId: row[0] as int,
          username: row[1] as String,
          fullName: row[2] as String? ?? '',
          roleId: row[3] as int,
          roleName: row[6] as String?,
          isActive: row[4] as bool,
          createdAt: DateTime.parse(row[5] as String),
        );
      }).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Get all roles
  Future<List<Role>> getAllRoles() async {
    try {
      final conn = await _databaseService.connection;

      final result = await conn.execute('SELECT role_id, role_name FROM roles ORDER BY role_id');

      return result.map((row) {
        return Role(
          roleId: row[0] as int,
          roleName: row[1] as String,
        );
      }).toList();
    } catch (e) {
      print('Error getting all roles: $e');
      return [];
    }
  }

  // Create new user (admin only)
  Future<bool> createUser({
    required String username,
    required String password,
    required String fullName,
    required int roleId,
  }) async {
    try {
      final conn = await _databaseService.connection;

      final hashedPassword = _hashPassword(password);

      await conn.execute(Sql.named('''
        INSERT INTO users (username, password_hash, full_name, role_id, is_active)
        VALUES (@username, @password, @full_name, @role_id, TRUE)
      '''), parameters: {
        'username': username,
        'password': hashedPassword,
        'full_name': fullName,
        'role_id': roleId,
      });

      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
    required int userId,
    String? username,
    String? fullName,
    int? roleId,
    bool? isActive,
    String? password,
  }) async {
    try {
      final conn = await _databaseService.connection;

      final updates = <String, dynamic>{};
      final parameters = <dynamic>[];
      int paramIndex = 1;

      if (username != null) {
        updates['username'] = username;
        parameters.add(username);
      }
      if (fullName != null) {
        updates['full_name'] = fullName;
        parameters.add(fullName);
      }
      if (roleId != null) {
        updates['role_id'] = roleId;
        parameters.add(roleId);
      }
      if (isActive != null) {
        updates['is_active'] = isActive;
        parameters.add(isActive);
      }
      if (password != null) {
        updates['password_hash'] = _hashPassword(password);
        parameters.add(_hashPassword(password));
      }

      if (updates.isEmpty) return false;

      final Map<String, dynamic> sqlParams = {};
      for (var entry in updates.entries) {
        sqlParams[entry.key] = parameters[paramIndex - updates.length + updates.keys.toList().indexOf(entry.key)];
      }
      sqlParams['user_id'] = userId;

      final setClause = updates.keys.map((key) => '$key = @$key').join(', ');

      await conn.execute(Sql.named('''
        UPDATE users
        SET $setClause
        WHERE user_id = @user_id
      '''), parameters: sqlParams);

      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete user (soft delete by setting is_active to false)
  Future<bool> deleteUser(int userId) async {
    try {
      final conn = await _databaseService.connection;

      await conn.execute(Sql.named('UPDATE users SET is_active = FALSE WHERE user_id = @user_id'), parameters: {'user_id': userId});

      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    try {
      final session = await getCurrentSession();
      if (session == null) return false;

      // Simple permission check based on role
      switch (permission.toLowerCase()) {
        case 'view_products':
        case 'view_sales':
          return true; // All roles can view
        case 'manage_products':
        case 'manage_users':
        case 'view_reports':
          return session.isAdmin || session.isManager;
        case 'process_sales':
          return session.isAdmin || session.isCashier || session.isManager;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }
}