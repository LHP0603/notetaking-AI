part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String accessToken;
  final String refreshToken;

  const AuthAuthenticated({
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  List<Object> get props => [accessToken, refreshToken];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthSignupSuccess extends AuthState {
  final String email;

  const AuthSignupSuccess(this.email);

  @override
  List<Object> get props => [email];
}