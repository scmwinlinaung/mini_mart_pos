import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mini_mart_pos/data/models/auth.dart';
import 'package:mini_mart_pos/data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthState.initial());

  // Initialize auth state
  Future<void> initialize() async {
    emit(const AuthState.loading());
    try {
      final session = await _authRepository.getCurrentSession();
      if (session != null) {
        emit(AuthState.authenticated(session));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  // Login user
  Future<void> login(String username, String password) async {
    emit(const AuthState.loading());
    try {
      final response = await _authRepository.authenticate(username, password);

      if (response.success && response.user != null) {
        final session = UserSession(
          user: response.user!,
          loginTime: DateTime.now(),
          authToken: 'generated_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        emit(AuthState.authenticated(session));
      } else {
        emit(AuthState.error(response.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Logout failed: ${e.toString()}'));
    }
  }

  // Clear error
  void clearError() {
    if (state.status == AuthStatus.error) {
      emit(const AuthState.unauthenticated());
    }
  }

  // Check if user has permission
  Future<bool> hasPermission(String permission) async {
    return await _authRepository.hasPermission(permission);
  }

  // Get current session
  UserSession? get currentSession {
    return state.whenOrNull(
      authenticated: (session) => session,
    );
  }

  // Check if user is admin
  bool get isAdmin {
    return currentSession?.isAdmin ?? false;
  }

  // Check if user is cashier
  bool get isCashier {
    return currentSession?.isCashier ?? false;
  }

  // Check if user is manager
  bool get isManager {
    return currentSession?.isManager ?? false;
  }
}