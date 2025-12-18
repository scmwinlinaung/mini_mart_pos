part of 'user_cubit.dart';

class UserState {
  final List<User> users;
  final User? selectedUser;
  final bool isLoading;
  final String? error;
  final bool isEditing;
  final bool showPassword;
  final List<Role> availableRoles;

  // Form fields
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String confirmPassword;
  final Role selectedRole;
  final bool isActive;

  // Form errors
  final String? usernameError;
  final String? fullNameError;
  final String? emailError;
  final String? phoneError;
  final String? passwordError;
  final String? confirmPasswordError;

  const UserState({
    this.users = const [],
    this.selectedUser,
    this.isLoading = false,
    this.error,
    this.isEditing = false,
    this.showPassword = false,
    this.availableRoles = const [],
    this.username = '',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.confirmPassword = '',
    this.selectedRole = Role.cashier,
    this.isActive = true,
    this.usernameError,
    this.fullNameError,
    this.emailError,
    this.phoneError,
    this.passwordError,
    this.confirmPasswordError,
  });

  UserState copyWith({
    List<User>? users,
    User? selectedUser,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isEditing,
    bool? showPassword,
    List<Role>? availableRoles,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? confirmPassword,
    Role? selectedRole,
    bool? isActive,
    String? usernameError,
    String? fullNameError,
    String? emailError,
    String? phoneError,
    String? passwordError,
    String? confirmPasswordError,
    bool clearUsernameError = false,
    bool clearFullNameError = false,
    bool clearEmailError = false,
    bool clearPhoneError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
    bool clearAllErrors = false,
  }) {
    return UserState(
      users: users ?? this.users,
      selectedUser: selectedUser ?? this.selectedUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isEditing: isEditing ?? this.isEditing,
      showPassword: showPassword ?? this.showPassword,
      availableRoles: availableRoles ?? this.availableRoles,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      selectedRole: selectedRole ?? this.selectedRole,
      isActive: isActive ?? this.isActive,
      usernameError: clearUsernameError || clearAllErrors ? null : (usernameError ?? this.usernameError),
      fullNameError: clearFullNameError || clearAllErrors ? null : (fullNameError ?? this.fullNameError),
      emailError: clearEmailError || clearAllErrors ? null : (emailError ?? this.emailError),
      phoneError: clearPhoneError || clearAllErrors ? null : (phoneError ?? this.phoneError),
      passwordError: clearPasswordError || clearAllErrors ? null : (passwordError ?? this.passwordError),
      confirmPasswordError: clearConfirmPasswordError || clearAllErrors ? null : (confirmPasswordError ?? this.confirmPasswordError),
    );
  }

  bool get isFormValid {
    return username.isNotEmpty &&
        fullName.isNotEmpty &&
        password.isNotEmpty &&
        (isEditing || confirmPassword.isNotEmpty) &&
        usernameError == null &&
        fullNameError == null &&
        emailError == null &&
        phoneError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }
}