import '../models/auth.dart';
import '../services/user_database_service.dart';
import '../../core/services/database_service.dart';

class UserRepository {
  final UserDatabaseService _userDbService;

  UserRepository(DatabaseService dbService)
    : _userDbService = UserDatabaseService(dbService);

  // CRUD Operations
  Future<List<User>> getAllUsers() async {
    try {
      return await _userDbService.getAllUsers();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<User?> getUserById(int userId) async {
    try {
      return await _userDbService.getUserById(userId);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  Future<int> createUser({
    required String username,
    required String password,
    required String fullName,
    required Role role,
    String? email,
    String? phone,
  }) async {
    try {
      // Validate input
      await _validateUserData(
        username: username,
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );

      // Check if username is already taken
      final isUsernameTaken = await _userDbService.usernameExists(username);
      if (isUsernameTaken) {
        throw Exception('Username is already taken');
      }

      // Hash password (in a real app, use proper password hashing)
      final passwordHash = _hashPassword(password);

      return await _userDbService.createUser(
        username: username,
        password: passwordHash,
        fullName: fullName,
        role: role,
        email: email,
      );
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<bool> updateUser(
    int userId, {
    String? username,
    String? password,
    String? fullName,
    Role? role,
    String? email,
    String? phone,
    bool? isActive,
  }) async {
    try {
      // Validate input if provided
      if (username != null ||
          fullName != null ||
          email != null ||
          phone != null ||
          password != null) {
        final existingUser = await _userDbService.getUserById(userId);
        if (existingUser == null) {
          throw Exception('User not found');
        }

        await _validateUserData(
          username: username ?? existingUser.username,
          fullName: fullName ?? existingUser.fullName,
          email: email ?? existingUser.email,
          password: password,
          isUpdate: true,
        );
      }

      // Check if username is taken by another user
      if (username != null) {
        final isUsernameTaken = await _userDbService.usernameExists(username);
        if (isUsernameTaken) {
          throw Exception('Username is already taken');
        }
      }

      String? passwordHash;
      if (password != null) {
        passwordHash = _hashPassword(password);
      }

      await _userDbService.updateUser(
        userId,
        username: username,
        password: passwordHash,
        fullName: fullName,
        role: role,
        email: email,
        isActive: isActive,
      );
      return true;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<bool> deactivateUser(int userId) async {
    try {
      await _userDbService.deactivateUser(userId);
      return true;
    } catch (e) {
      throw Exception('Failed to deactivate user: $e');
    }
  }

  Future<bool> activateUser(int userId) async {
    try {
      await _userDbService.activateUser(userId);
      return true;
    } catch (e) {
      throw Exception('Failed to activate user: $e');
    }
  }

  // Authentication
  Future<User?> authenticateUser(String username, String password) async {
    try {
      final passwordHash = _hashPassword(password);
      return await _userDbService.authenticateUser(username, passwordHash);
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  // Role Management
  Future<List<Role>> getAllRoles() async {
    try {
      return await _userDbService.getAllRoles();
    } catch (e) {
      throw Exception('Failed to fetch roles: $e');
    }
  }

  // Business Logic
  Future<List<User>> getActiveUsers() async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) => user.isActive).toList();
    } catch (e) {
      throw Exception('Failed to fetch active users: $e');
    }
  }

  Future<List<User>> getUsersByRole(Role role) async {
    try {
      final allUsers = await getAllUsers();
      return allUsers.where((user) => user.role == role).toList();
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final allUsers = await getAllUsers();
      final activeUsers = allUsers.where((user) => user.isActive).toList();

      final roleCounts = <Role, int>{};
      for (final user in allUsers) {
        roleCounts[user.role] = (roleCounts[user.role] ?? 0) + 1;
      }

      return {
        'totalUsers': allUsers.length,
        'activeUsers': activeUsers.length,
        'inactiveUsers': allUsers.length - activeUsers.length,
        'roleDistribution': roleCounts.map(
          (role, count) => MapEntry(role.name, count),
        ),
      };
    } catch (e) {
      throw Exception('Failed to fetch user statistics: $e');
    }
  }

  Future<bool> isUsernameAvailable(
    String username, {
    int? excludeUserId,
  }) async {
    try {
      return !(await _userDbService.usernameExists(username));
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Validation
  Future<void> _validateUserData({
    required String username,
    required String fullName,
    String? email,
    String? phone,
    String? password,
    bool isUpdate = false,
  }) async {
    // Username validation
    if (username.trim().isEmpty) {
      throw Exception('Username is required');
    }
    if (username.length < 3) {
      throw Exception('Username must be at least 3 characters long');
    }
    if (username.length > 50) {
      throw Exception('Username must be less than 50 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      throw Exception(
        'Username can only contain letters, numbers, and underscores',
      );
    }

    // Full name validation
    if (fullName.trim().isEmpty) {
      throw Exception('Full name is required');
    }
    if (fullName.length > 100) {
      throw Exception('Full name must be less than 100 characters');
    }

    // Email validation
    if (email != null && email.isNotEmpty) {
      if (email.length > 100) {
        throw Exception('Email must be less than 100 characters');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Invalid email format');
      }
    }

    // Phone validation
    if (phone != null && phone.isNotEmpty) {
      if (phone.length > 20) {
        throw Exception('Phone number must be less than 20 characters');
      }
      if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phone)) {
        throw Exception(
          'Phone number can only contain digits, spaces, and common phone symbols',
        );
      }
    }

    // Password validation (only for new users or when updating password)
    if (!isUpdate || password != null) {
      if (password == null || password.isEmpty) {
        throw Exception('Password is required');
      }
      if (password.length < 8) {
        throw Exception('Password must be at least 8 characters long');
      }
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
        throw Exception(
          'Password must contain at least one lowercase letter, one uppercase letter, and one number',
        );
      }
    }
  }

  // Password hashing (in a real app, use bcrypt or argon2)
  String _hashPassword(String password) {
    // This is a simple hash for demonstration - use proper password hashing in production
    return password.split('').reversed.join(); // Simple reverse for demo
  }
}
