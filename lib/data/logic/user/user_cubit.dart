import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/auth.dart';
import '../../repositories/user_repository.dart';
import '../../../core/service_locator.dart';
import '../../../core/services/database_service.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  late final UserRepository _userRepository;

  UserCubit() : super(const UserState()) {
    _userRepository = UserRepository(sl<DatabaseService>());
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadUsers(),
      loadRoles(),
    ]);
  }

  Future<void> loadUsers() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final users = await _userRepository.getAllUsers();

      emit(state.copyWith(
        users: users,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadRoles() async {
    try {
      final roles = await _userRepository.getAllRoles();
      emit(state.copyWith(availableRoles: roles));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void selectUser(User? user) {
    if (user != null) {
      emit(state.copyWith(
        selectedUser: user,
        isEditing: true,
        username: user.username,
        fullName: user.fullName,
        email: user.email,
        phone: '', // Phone field removed from User model
        selectedRole: user.role,
        isActive: user.isActive,
        password: '',
        confirmPassword: '',
        clearAllErrors: true,
      ));
    } else {
      emit(state.copyWith(
        selectedUser: null,
        isEditing: false,
        username: '',
        fullName: '',
        email: '',
        phone: '',
        selectedRole: Role.cashier,
        isActive: true,
        password: '',
        confirmPassword: '',
        clearAllErrors: true,
      ));
    }
  }

  void updateUsername(String value) {
    emit(state.copyWith(username: value));
    _validateUsername();
  }

  void updateFullName(String value) {
    emit(state.copyWith(fullName: value));
    _validateFullName();
  }

  void updateEmail(String value) {
    emit(state.copyWith(email: value));
    _validateEmail();
  }

  void updatePhone(String value) {
    emit(state.copyWith(phone: value));
    _validatePhone();
  }

  void updatePassword(String value) {
    emit(state.copyWith(password: value));
    _validatePassword();
  }

  void updateConfirmPassword(String value) {
    emit(state.copyWith(confirmPassword: value));
    _validateConfirmPassword();
  }

  void updateRole(Role role) {
    emit(state.copyWith(selectedRole: role));
  }

  void updateIsActive(bool value) {
    emit(state.copyWith(isActive: value));
  }

  void togglePasswordVisibility() {
    emit(state.copyWith(showPassword: !state.showPassword));
  }

  Future<void> saveUser() async {
    try {
      // Validate all fields
      if (!_validateAllFields()) {
        return;
      }

      emit(state.copyWith(isLoading: true, clearError: true));

      if (state.isEditing && state.selectedUser != null) {
        // Update existing user
        await _userRepository.updateUser(
          state.selectedUser!.id,
          username: state.username,
          fullName: state.fullName,
          email: state.email.isEmpty ? null : state.email,
          phone: state.phone.isEmpty ? null : state.phone,
          role: state.selectedRole,
          password: state.password.isNotEmpty ? state.password : null,
          isActive: state.isActive,
        );
      } else {
        // Create new user
        await _userRepository.createUser(
          username: state.username,
          password: state.password,
          fullName: state.fullName,
          email: state.email.isEmpty ? null : state.email,
          phone: state.phone.isEmpty ? null : state.phone,
          role: state.selectedRole,
        );
      }

      // Reload users and reset form
      await loadUsers();
      selectUser(null);

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _userRepository.deactivateUser(userId);

      await loadUsers();

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> activateUser(int userId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _userRepository.activateUser(userId);

      await loadUsers();

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void clearForm() {
    selectUser(null);
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  bool _validateAllFields() {
    var isValid = true;

    isValid &= _validateUsername();
    isValid &= _validateFullName();
    isValid &= _validateEmail();
    isValid &= _validatePhone();
    isValid &= _validatePassword();
    isValid &= _validateConfirmPassword();

    return isValid;
  }

  bool _validateUsername() {
    final username = state.username;
    if (username.trim().isEmpty) {
      emit(state.copyWith(usernameError: 'Username is required'));
      return false;
    }
    if (username.length < 3) {
      emit(state.copyWith(usernameError: 'Username must be at least 3 characters'));
      return false;
    }
    if (username.length > 50) {
      emit(state.copyWith(usernameError: 'Username must be less than 50 characters'));
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      emit(state.copyWith(usernameError: 'Username can only contain letters, numbers, and underscores'));
      return false;
    }

    emit(state.copyWith(clearUsernameError: true));
    return true;
  }

  bool _validateFullName() {
    final fullName = state.fullName;
    if (fullName.trim().isEmpty) {
      emit(state.copyWith(fullNameError: 'Full name is required'));
      return false;
    }
    if (fullName.length > 100) {
      emit(state.copyWith(fullNameError: 'Full name must be less than 100 characters'));
      return false;
    }

    emit(state.copyWith(clearFullNameError: true));
    return true;
  }

  bool _validateEmail() {
    final email = state.email;
    if (email.isNotEmpty) {
      if (email.length > 100) {
        emit(state.copyWith(emailError: 'Email must be less than 100 characters'));
        return false;
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        emit(state.copyWith(emailError: 'Invalid email format'));
        return false;
      }
    }

    emit(state.copyWith(clearEmailError: true));
    return true;
  }

  bool _validatePhone() {
    final phone = state.phone;
    if (phone.isNotEmpty) {
      if (phone.length > 20) {
        emit(state.copyWith(phoneError: 'Phone number must be less than 20 characters'));
        return false;
      }
      if (!RegExp(r'^[\d\s\-\+\(\)]+$').hasMatch(phone)) {
        emit(state.copyWith(phoneError: 'Phone number can only contain digits, spaces, and common symbols'));
        return false;
      }
    }

    emit(state.copyWith(clearPhoneError: true));
    return true;
  }

  bool _validatePassword() {
    final password = state.password;

    // Password is required for new users
    if (!state.isEditing && password.isEmpty) {
      emit(state.copyWith(passwordError: 'Password is required'));
      return false;
    }

    // If password is provided (new user or password change), validate it
    if (password.isNotEmpty) {
      if (password.length < 8) {
        emit(state.copyWith(passwordError: 'Password must be at least 8 characters'));
        return false;
      }
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
        emit(state.copyWith(passwordError: 'Password must contain uppercase, lowercase, and number'));
        return false;
      }
    }

    emit(state.copyWith(clearPasswordError: true));
    return true;
  }

  bool _validateConfirmPassword() {
    // Confirm password is required for new users
    if (!state.isEditing && state.confirmPassword.isEmpty) {
      emit(state.copyWith(confirmPasswordError: 'Please confirm your password'));
      return false;
    }

    // If password is provided, confirm password must match
    if (state.password.isNotEmpty && state.password != state.confirmPassword) {
      emit(state.copyWith(confirmPasswordError: 'Passwords do not match'));
      return false;
    }

    emit(state.copyWith(clearConfirmPasswordError: true));
    return true;
  }
}