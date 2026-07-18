enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
