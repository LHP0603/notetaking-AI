import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/usecase.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_stored_auth.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/refresh_token.dart';
import '../../domain/usecases/register_user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUser _registerUser;
  final LoginUser _loginUser;
  final RefreshTokenUseCase _refreshToken;
  final LogoutUser _logoutUser;
  final GetStoredAuth _getStoredAuth;

  AuthBloc({
    required RegisterUser registerUser,
    required LoginUser loginUser,
    required RefreshTokenUseCase refreshToken,
    required LogoutUser logoutUser,
    required GetStoredAuth getStoredAuth,
  })  : _registerUser = registerUser,
        _loginUser = loginUser,
        _refreshToken = refreshToken,
        _logoutUser = logoutUser,
        _getStoredAuth = getStoredAuth,
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _registerUser(
      RegisterParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(
        AuthRegistered(
          user: user,
          message: 'Registration successful! Please login.',
        ),
      ),
    );
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await _loginUser(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authResponse) => emit(
        AuthAuthenticated(
          authResponse: authResponse,
          message: 'Welcome back!',
        ),
      ),
    );
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _refreshToken(
      RefreshTokenParams(refreshToken: event.refreshToken),
    );

    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (authResponse) => emit(
        AuthTokenRefreshed(
          authResponse: authResponse,
          message: 'Session refreshed',
        ),
      ),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _logoutUser(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getStoredAuth(NoParams());
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (authResponse) => authResponse == null
          ? emit(AuthUnauthenticated())
          : emit(
            AuthAuthenticated(
              authResponse: authResponse,
              message: 'Welcome back!',
            ),
          ),
    );
  }
}
