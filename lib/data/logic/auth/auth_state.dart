part of 'auth_cubit.dart';

class AuthState extends Equatable {
  final AuthStatus status;
  final UserSession? session;
  final String? error;

  const AuthState._({
    required this.status,
    this.session,
    this.error,
  });

  const AuthState.initial() : this._(status: AuthStatus.initial);

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated(UserSession session)
      : this._(status: AuthStatus.authenticated, session: session);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  const AuthState.error(String error)
      : this._(status: AuthStatus.error, error: error);

  @override
  List<Object?> get props => [status, session, error];

  @override
  String toString() {
    return 'AuthState{status: $status, session: $session, error: $error}';
  }

  // Convenience getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get hasError => status == AuthStatus.error;

  // When pattern matching
  T? when<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(UserSession session)? authenticated,
    T Function()? unauthenticated,
    T Function(String error)? error,
  }) {
    switch (status) {
      case AuthStatus.initial:
        return initial?.call();
      case AuthStatus.loading:
        return loading?.call();
      case AuthStatus.authenticated:
        return authenticated?.call(session!);
      case AuthStatus.unauthenticated:
        return unauthenticated?.call();
      case AuthStatus.error:
        return error?.call(this.error!);
    }
  }

  // When pattern matching with optional fallback
  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(UserSession session)? authenticated,
    T Function()? unauthenticated,
    T Function(String error)? error,
  }) {
    return when(
      initial: initial,
      loading: loading,
      authenticated: authenticated,
      unauthenticated: unauthenticated,
      error: error,
    );
  }

  // Map the state to another value
  R map<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(UserSession session) authenticated,
    required R Function() unauthenticated,
    required R Function(String error) error,
  }) {
    switch (status) {
      case AuthStatus.initial:
        return initial();
      case AuthStatus.loading:
        return loading();
      case AuthStatus.authenticated:
        return authenticated(session!);
      case AuthStatus.unauthenticated:
        return unauthenticated();
      case AuthStatus.error:
        return error(this.error!);
    }
  }

  // Map the state to another value with optional fallback
  R? mapOrNull<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(UserSession session)? authenticated,
    R Function()? unauthenticated,
    R Function(String error)? error,
  }) {
    return map(
      initial: initial ?? () => throw UnimplementedError('initial not provided'),
      loading: loading ?? () => throw UnimplementedError('loading not provided'),
      authenticated: authenticated ?? (session) => throw UnimplementedError('authenticated not provided'),
      unauthenticated: unauthenticated ?? () => throw UnimplementedError('unauthenticated not provided'),
      error: error ?? (error) => throw UnimplementedError('error not provided'),
    );
  }
}