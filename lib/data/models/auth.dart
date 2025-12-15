class User {
  final int userId;
  final String username;
  final String fullName;
  final int roleId;
  final String? roleName;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.roleId,
    this.roleName,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'] as int,
      username: map['username'] as String,
      fullName: map['full_name'] as String? ?? '',
      roleId: map['role_id'] as int,
      roleName: map['role_name'] as String?,
      isActive: map['is_active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'role_id': roleId,
      'role_name': roleName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? userId,
    String? username,
    String? fullName,
    int? roleId,
    String? roleName,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username;

  @override
  int get hashCode => userId.hashCode ^ username.hashCode;

  @override
  String toString() {
    return 'User{userId: $userId, username: $username, fullName: $fullName, roleId: $roleId, roleName: $roleName}';
  }
}

class Role {
  final int roleId;
  final String roleName;

  Role({
    required this.roleId,
    required this.roleName,
  });

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      roleId: map['role_id'] as int,
      roleName: map['role_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role_id': roleId,
      'role_name': roleName,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role &&
          runtimeType == other.runtimeType &&
          roleId == other.roleId &&
          roleName == other.roleName;

  @override
  int get hashCode => roleId.hashCode ^ roleName.hashCode;

  @override
  String toString() {
    return 'Role{roleId: $roleId, roleName: $roleName}';
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final User? user;
  final String? error;

  LoginResponse({
    required this.success,
    this.user,
    this.error,
  });

  factory LoginResponse.success(User user) {
    return LoginResponse(
      success: true,
      user: user,
    );
  }

  factory LoginResponse.error(String error) {
    return LoginResponse(
      success: false,
      error: error,
    );
  }
}

class UserSession {
  final User user;
  final DateTime loginTime;
  final String? authToken;

  UserSession({
    required this.user,
    required this.loginTime,
    this.authToken,
  });

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      user: User.fromMap(map['user'] as Map<String, dynamic>),
      loginTime: DateTime.parse(map['login_time'] as String),
      authToken: map['auth_token'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user': user.toMap(),
      'login_time': loginTime.toIso8601String(),
      'auth_token': authToken,
    };
  }

  bool get isAdmin => user.roleName?.toLowerCase() == 'admin';
  bool get isCashier => user.roleName?.toLowerCase() == 'cashier';
  bool get isManager => user.roleName?.toLowerCase() == 'manager';

  UserSession copyWith({
    User? user,
    DateTime? loginTime,
    String? authToken,
  }) {
    return UserSession(
      user: user ?? this.user,
      loginTime: loginTime ?? this.loginTime,
      authToken: authToken ?? this.authToken,
    );
  }
}

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

extension AuthStatusExtension on AuthStatus {
  bool get isAuthenticated => this == AuthStatus.authenticated;
  bool get isLoading => this == AuthStatus.loading;
  bool get isUnauthenticated => this == AuthStatus.unauthenticated;
  bool get hasError => this == AuthStatus.error;
}