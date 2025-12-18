enum Role {
  admin('Admin', 'စီမံခန့်ခွဲသူ'),
  manager('Manager', 'မန်နေဂျာ'),
  cashier('Cashier', 'ငွေကိုင်');

  const Role(this.englishName, this.myanmarName);
  final String englishName;
  final String myanmarName;

  String getDisplayName(String languageCode) {
    return languageCode == 'my' ? myanmarName : englishName;
  }

  static Role fromString(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'admin':
      case 'စီမံခန့်ခွဲသူ':
        return Role.admin;
      case 'manager':
      case 'မန်နေဂျာ':
        return Role.manager;
      case 'cashier':
      case 'ငွေကိုင်':
        return Role.cashier;
      default:
        return Role.cashier;
    }
  }

  // For backward compatibility
  String get name => englishName;
}

class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String password; // Hashed password
  final Role role;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    this.email = '',
    required this.password,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['user_id'] as int,
      username: map['username'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String? ?? '',
      password: map['password_hash'] as String? ?? '',
      role: _parseRole(map['role_name'] as String?),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'password_hash': password,
      'role_name': role.name,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    String? password,
    Role? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Role _parseRole(String? roleName) {
    if (roleName == null) return Role.cashier;
    return Role.fromString(roleName);
  }

  bool get isAdmin => role == Role.admin;
  bool get isManager => role == Role.manager;
  bool get isCashier => role == Role.cashier;
  bool get isEmployee => role == Role.cashier;

  // Add missing getters
  String get roleName => role.name;
  int get userId => id;

  // Method to get localized role name
  String getLocalizedRoleName(String languageCode) {
    return role.getDisplayName(languageCode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;

  @override
  String toString() {
    return 'User{id: $id, username: $username, fullName: $fullName, role: ${role.name}}';
  }
}

class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toMap() {
    return {'username': username, 'password': password};
  }
}

class LoginResponse {
  final bool success;
  final User? user;
  final String? error;

  LoginResponse({required this.success, this.user, this.error});

  factory LoginResponse.success(User user) {
    return LoginResponse(success: true, user: user);
  }

  factory LoginResponse.error(String error) {
    return LoginResponse(success: false, error: error);
  }
}

class UserSession {
  final User user;
  final DateTime loginTime;
  final String? authToken;

  UserSession({required this.user, required this.loginTime, this.authToken});

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

  bool get isAdmin => user.isAdmin;
  bool get isCashier => user.isCashier;
  bool get isManager => user.isManager;
  bool get isEmployee => user.isEmployee;

  UserSession copyWith({User? user, DateTime? loginTime, String? authToken}) {
    return UserSession(
      user: user ?? this.user,
      loginTime: loginTime ?? this.loginTime,
      authToken: authToken ?? this.authToken,
    );
  }
}

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

extension AuthStatusExtension on AuthStatus {
  bool get isAuthenticated => this == AuthStatus.authenticated;
  bool get isLoading => this == AuthStatus.loading;
  bool get isUnauthenticated => this == AuthStatus.unauthenticated;
  bool get hasError => this == AuthStatus.error;
}
