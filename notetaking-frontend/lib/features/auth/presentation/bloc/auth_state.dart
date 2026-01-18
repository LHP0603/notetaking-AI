part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthRegistered extends AuthState {
  final User user;
  final String message;

  const AuthRegistered({
    required this.user,
    required this.message,
  });

  @override
  List<Object?> get props => [user, message];
}

class AuthAuthenticated extends AuthState {
  final AuthResponse authResponse;
  final String message;

  const AuthAuthenticated({
    required this.authResponse,
    required this.message,
  });

  @override
  List<Object> get props => [authResponse, message];
}

class AuthTokenRefreshed extends AuthState {
  final AuthResponse authResponse;
  final String message;

  const AuthTokenRefreshed({
    required this.authResponse,
    required this.message,
  });

  @override
  List<Object> get props => [authResponse, message];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
