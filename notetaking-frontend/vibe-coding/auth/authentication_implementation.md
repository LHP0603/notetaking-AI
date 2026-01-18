# Authentication Feature Implementation Guide

## Overview

This document outlines the implementation of the authentication feature for Voicely app, including user registration, login, and token refresh functionality. The implementation follows Clean Architecture principles with dependency injection using GetIt and state management using BLoC pattern.

## Table of Contents

1. [API Endpoints & Responses](#api-endpoints--responses)
2. [Architecture Overview](#architecture-overview)
3. [Implementation Steps](#implementation-steps)
4. [File Structure](#file-structure)
5. [Code Implementation](#code-implementation)
6. [Dependency Injection](#dependency-injection)
7. [Error Handling](#error-handling)
8. [Testing Considerations](#testing-considerations)

---

## API Endpoints & Responses

### 1. Register

**Endpoint:** `POST /auth/register`

**Payload:**
```json
{
  "email": "user@example.com",
  "password": "string"
}
```

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "USER_REGISTERED_SUCCESS",
  "data": {
    "id": 3,
    "email": "dang@gmail.com",
    "is_active": true,
    "created_at": "2025-12-24T13:46:00.903252"
  }
}
```

### 2. Login

**Endpoint:** `POST /auth/login`

**Payload:**
```json
{
  "email": "user@example.com",
  "password": "string"
}
```

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "LOGIN_SUCCESS",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
  }
}
```

**Storage Requirements:**
- Store `access_token` in Flutter Secure Storage
- Store `refresh_token` in Flutter Secure Storage
- Use these keys: `access_token`, `refresh_token` (from `AppConstants`)

### 3. Refresh Token

**Endpoint:** `POST /auth/refresh`

**Payload:**
```json
{
  "refresh_token": "string"
}
```

**Response:**
```json
{
  "code": 200,
  "success": true,
  "message": "TOKEN_REFRESHED_SUCCESS",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "token_type": "bearer"
  }
}
```

**Purpose:**
When the access token expires, use the refresh token to obtain a new access token, ensuring seamless user authentication without requiring re-login.

---

## Architecture Overview

The authentication feature follows Clean Architecture with three main layers:

```
features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_local_data_source.dart      # Flutter Secure Storage operations
│   │   └── auth_remote_data_source.dart     # API calls
│   ├── models/
│   │   ├── auth_response_model.dart         # API response models
│   │   └── user_model.dart                  # User data model
│   └── repositories/
│       └── auth_repository_impl.dart        # Repository implementation
├── domain/
│   ├── entities/
│   │   ├── auth_response.dart               # Business entities
│   │   └── user.dart
│   ├── repositories/
│   │   └── auth_repository.dart             # Repository interface
│   └── usecases/
│       ├── register_user.dart               # Registration use case
│       ├── login_user.dart                  # Login use case
│       └── refresh_token.dart               # Token refresh use case
└── presentation/
    ├── bloc/
    │   ├── auth_bloc.dart                   # BLoC state management
    │   ├── auth_event.dart                  # BLoC events
    │   └── auth_state.dart                  # BLoC states
    ├── pages/
    │   ├── login_page.dart                  # Login UI
    │   └── signup_page.dart                 # Registration UI
    └── widgets/
        ├── auth_button.dart                 # Reusable widgets
        └── auth_text_field.dart
```

---

## Implementation Steps

### Phase 1: Domain Layer

1. Create `User` entity
2. Create `AuthResponse` entity
3. Define `AuthRepository` interface
4. Implement use cases:
   - `RegisterUser`
   - `LoginUser`
   - `RefreshToken`

### Phase 2: Data Layer

1. Create data models:
   - `UserModel` extending `User`
   - `AuthResponseModel` extending `AuthResponse`
2. Implement data sources:
   - `AuthLocalDataSource` for secure storage
   - `AuthRemoteDataSource` for API calls
3. Implement `AuthRepositoryImpl`

### Phase 3: Presentation Layer

1. Create BLoC:
   - Define events (Register, Login, RefreshToken)
   - Define states (Initial, Loading, Success, Error)
   - Implement event handlers
2. Create UI pages (Login, Signup)
3. Integrate BLoC with UI

### Phase 4: Dependency Injection

1. Register dependencies in `injection_container.dart`
2. Set up proper dependency graph

---

## Code Implementation

### 1. Domain Layer

#### entities/auth_response.dart
```dart
import 'package:equatable/equatable.dart';

class AuthResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType];
}
```

#### entities/user.dart
```dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String email;
  final bool isActive;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, isActive, createdAt];
}
```

**Note:** The backend User model also contains `hashed_password`, `updated_at`, and relationships (`audio_files`, `notes`, `task_jobs`, `chatbot_sessions`, `devices`), but these are not exposed to the frontend for security and efficiency reasons.

#### repositories/auth_repository.dart
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> register(String email, String password);
  Future<Either<Failure, AuthResponse>> login(String email, String password);
  Future<Either<Failure, AuthResponse>> refreshToken(String refreshToken);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
}
```

#### usecases/register_user.dart
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    return await repository.register(params.email, params.password);
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;

  const RegisterParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
```

#### usecases/login_user.dart
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class LoginUser implements UseCase<AuthResponse, LoginParams> {
  final AuthRepository repository;

  LoginUser(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(LoginParams params) async {
    return await repository.login(params.email, params.password);
  }
}

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
```

#### usecases/refresh_token.dart
```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class RefreshTokenUseCase implements UseCase<AuthResponse, RefreshTokenParams> {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(RefreshTokenParams params) async {
    return await repository.refreshToken(params.refreshToken);
  }
}

class RefreshTokenParams extends Equatable {
  final String refreshToken;

  const RefreshTokenParams({required this.refreshToken});

  @override
  List<Object> get props => [refreshToken];
}
```

### 2. Data Layer

#### models/user_model.dart
```dart
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.isActive,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  UserModel copyWith({
    int? id,
    String? email,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

**Backend Model Mapping:**
- `id` → `users.id` (Integer, primary key, indexed)
- `email` → `users.email` (String, unique, indexed, not null)
- `isActive` → `users.is_active` (Boolean, default: true)
- `createdAt` → `users.created_at` (DateTime, UTC timezone)
- **Not exposed to frontend:**
  - `hashed_password` (String, not null) - Security
  - `updated_at` (DateTime, UTC, auto-updated) - Not needed for auth response
  - Relationships: `audio_files`, `notes`, `task_jobs`, `chatbot_sessions`, `devices` - Performance

#### models/auth_response_model.dart
```dart
import '../../domain/entities/auth_response.dart';

class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({
    required super.accessToken,
    required super.refreshToken,
    required super.tokenType,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
    };
  }
}
```

#### datasources/auth_local_data_source.dart
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: accessToken,
      ),
      secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      ),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: AppConstants.accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      secureStorage.delete(key: AppConstants.accessTokenKey),
      secureStorage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }
}
```

#### datasources/auth_remote_data_source.dart
```dart
import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register(String email, String password);
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> register(String email, String password) async {
    try {
      final response = await dio.post(
        AppConstants.signupEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return UserModel.fromJson(data['data']);
        } else {
          throw ServerException(
            message: data['message'] ?? 'Registration failed',
            code: data['code'] ?? 500,
          );
        }
      } else {
        throw ServerException(
          message: 'Registration failed',
          code: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        code: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        AppConstants.loginEndpoint,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return AuthResponseModel.fromJson(data['data']);
        } else {
          throw ServerException(
            message: data['message'] ?? 'Login failed',
            code: data['code'] ?? 500,
          );
        }
      } else {
        throw ServerException(
          message: 'Login failed',
          code: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        code: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        AppConstants.refreshTokenEndpoint,
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return AuthResponseModel.fromJson(data['data']);
        } else {
          throw ServerException(
            message: data['message'] ?? 'Token refresh failed',
            code: data['code'] ?? 500,
          );
        }
      } else {
        throw ServerException(
          message: 'Token refresh failed',
          code: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? 'Network error occurred',
        code: e.response?.statusCode ?? 500,
      );
    }
  }
}
```

#### repositories/auth_repository_impl.dart
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> register(
    String email,
    String password,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final user = await remoteDataSource.register(email, password);
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> login(
    String email,
    String password,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final authResponse = await remoteDataSource.login(email, password);
      
      // Save tokens to secure storage
      await localDataSource.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      
      return Right(authResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> refreshToken(
    String refreshToken,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final authResponse = await remoteDataSource.refreshToken(refreshToken);
      
      // Save new tokens to secure storage
      await localDataSource.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );
      
      return Right(authResponse);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearTokens();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to clear tokens'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      if (accessToken == null) {
        return const Right(null);
      }
      // TODO: Implement user fetch from token or cached user data
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to get current user'));
    }
  }
}
```

### 3. Presentation Layer

#### bloc/auth_event.dart
```dart
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;

  const RegisterRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RefreshTokenRequested extends AuthEvent {
  final String refreshToken;

  const RefreshTokenRequested({required this.refreshToken});

  @override
  List<Object?> get props => [refreshToken];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
```

#### bloc/auth_state.dart
```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';

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
  List<Object?> get props => [authResponse, message];
}

class AuthTokenRefreshed extends AuthState {
  final AuthResponse authResponse;
  final String message;

  const AuthTokenRefreshed({
    required this.authResponse,
    required this.message,
  });

  @override
  List<Object?> get props => [authResponse, message];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
```

#### bloc/auth_bloc.dart
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/refresh_token.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterUser _registerUser;
  final LoginUser _loginUser;
  final RefreshTokenUseCase _refreshToken;
  final AuthRepository _authRepository;

  AuthBloc({
    required RegisterUser registerUser,
    required LoginUser loginUser,
    required RefreshTokenUseCase refreshToken,
    required AuthRepository authRepository,
  })  : _registerUser = registerUser,
        _loginUser = loginUser,
        _refreshToken = refreshToken,
        _authRepository = authRepository,
        super(AuthInitial()) {
    on<RegisterRequested>(_onRegisterRequested);
    on<LoginRequested>(_onLoginRequested);
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
      (user) => emit(AuthRegistered(
        user: user,
        message: 'Registration successful! Please login.',
      )),
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
      (authResponse) => emit(AuthAuthenticated(
        authResponse: authResponse,
        message: 'Login successful!',
      )),
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
      (failure) {
        // If refresh fails, user needs to login again
        emit(AuthUnauthenticated());
      },
      (authResponse) => emit(AuthTokenRefreshed(
        authResponse: authResponse,
        message: 'Token refreshed successfully',
      )),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          // User is logged in, but we need to check if token is still valid
          // This can be done by making a test API call or checking token expiry
          emit(AuthInitial());
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }
}
```

---

## Dependency Injection

Update `injection_container.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> init() async {
  //! Features - Auth
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      registerUser: sl(),
      loginUser: sl(),
      refreshToken: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );

  //! External
  // Flutter Secure Storage
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  
  // ... existing code
}
```

---

## Error Handling

### Server Error Messages

Display user-friendly messages based on server response codes:

```dart
String getErrorMessage(String serverMessage) {
  switch (serverMessage) {
    case 'USER_REGISTERED_SUCCESS':
      return 'Registration successful! Please login.';
    case 'LOGIN_SUCCESS':
      return 'Welcome back!';
    case 'TOKEN_REFRESHED_SUCCESS':
      return 'Session refreshed';
    case 'USER_ALREADY_EXISTS':
      return 'This email is already registered';
    case 'INVALID_CREDENTIALS':
      return 'Invalid email or password';
    case 'TOKEN_EXPIRED':
      return 'Session expired. Please login again.';
    case 'INVALID_TOKEN':
      return 'Invalid session. Please login again.';
    default:
      return 'An error occurred. Please try again.';
  }
}
```

### Exception Classes

In `core/errors/exceptions.dart`:

```dart
class ServerException implements Exception {
  final String message;
  final int code;

  ServerException({
    required this.message,
    required this.code,
  });
}
```

### Failure Classes

In `core/errors/failures.dart`:

```dart
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}
```

---

## Token Refresh Strategy

### Automatic Token Refresh

Implement an interceptor in Dio to automatically refresh tokens when they expire:

```dart
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class TokenInterceptor extends Interceptor {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  TokenInterceptor({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add access token to headers
    final accessToken = await localDataSource.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired, try to refresh
      final refreshToken = await localDataSource.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          // Refresh the token
          final newAuthResponse = await remoteDataSource.refreshToken(refreshToken);
          
          // Save new tokens
          await localDataSource.saveTokens(
            accessToken: newAuthResponse.accessToken,
            refreshToken: newAuthResponse.refreshToken,
          );
          
          // Retry the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${newAuthResponse.accessToken}';
          
          final response = await Dio().fetch(options);
          handler.resolve(response);
          return;
        } catch (e) {
          // Refresh failed, user needs to login again
          await localDataSource.clearTokens();
          handler.next(err);
          return;
        }
      }
    }
    handler.next(err);
  }
}
```

---

## Testing Considerations

### Unit Tests

1. **Use Case Tests**: Test each use case in isolation
2. **Repository Tests**: Mock data sources and test repository logic
3. **BLoC Tests**: Test state transitions for each event

### Integration Tests

1. Test complete authentication flow
2. Test token refresh mechanism
3. Test error handling scenarios

### Widget Tests

1. Test login page UI
2. Test signup page UI
3. Test error message display

---

## Dependencies

Add these to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Functional Programming
  dartz: ^0.10.1
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # Networking
  dio: ^5.3.3
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # Others
  shared_preferences: ^2.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
  bloc_test: ^9.1.4
```

---

## Security Considerations

1. **Secure Storage**: Always use Flutter Secure Storage for tokens
2. **HTTPS**: Ensure all API calls use HTTPS in production
3. **Token Expiry**: Implement proper token expiry handling
4. **Input Validation**: Validate email and password formats
5. **Error Messages**: Don't expose sensitive information in error messages

---

## UI/UX Guidelines

### Success Messages

- **Registration**: "Registration successful! Please login."
- **Login**: "Welcome back!"
- **Token Refresh**: Silent (no user notification needed)

### Error Messages

- Display user-friendly messages based on server response
- Show loading indicators during API calls
- Provide clear validation feedback for form inputs

### Navigation

- After successful registration: Navigate to login page
- After successful login: Navigate to home/main page
- After token refresh failure: Navigate to login page
- After logout: Navigate to login page

---

## Implementation Checklist

- [ ] Create domain entities (User, AuthResponse)
- [ ] Create repository interface
- [ ] Implement use cases (Register, Login, RefreshToken)
- [ ] Create data models
- [ ] Implement remote data source
- [ ] Implement local data source (Flutter Secure Storage)
- [ ] Implement repository
- [ ] Create BLoC (events, states, bloc)
- [ ] Update dependency injection
- [ ] Implement token refresh interceptor
- [ ] Create/update UI pages (Login, Signup)
- [ ] Add error handling and user messages
- [ ] Test authentication flow
- [ ] Test token refresh mechanism
- [ ] Update app navigation based on auth state

---

## Notes

- The current project already has some auth implementation. Update existing files rather than replacing them entirely.
- Ensure consistency with existing code style and patterns.
- The API responses include `code`, `success`, and `message` fields - use these for proper error handling and user feedback.
- The token refresh should be automatic and transparent to the user.
- Consider implementing a splash screen that checks auth status on app startup.

---

## Next Steps

1. Review existing auth implementation
2. Identify missing pieces (likely register and refresh token)
3. Update/create necessary files
4. Test the complete authentication flow
5. Implement UI updates for better user feedback
6. Add comprehensive error handling
