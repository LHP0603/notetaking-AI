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

  // Demo/Test account credentials for development
  static const String _demoEmail = 'test@voicely.com';
  static const String _demoPassword = 'password123';
  static const bool _enableDemoAccount = true; // Set to false in production

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> register(String email, String password) async {
    try {
      final response = await dio.post(
        AppConstants.signupEndpoint,
        data: {'email': email, 'password': password},
      );

      final payload = _extractPayload(
        response,
        fallbackMessage: 'Registration failed',
      );
      return UserModel.fromJson(payload);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Registration failed');
    }
  }

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    // Check for demo account login
    if (_enableDemoAccount &&
        email == _demoEmail &&
        password == _demoPassword) {
      return AuthResponseModel(
        accessToken: 'demo_access_token_${DateTime.now().millisecondsSinceEpoch}',
        refreshToken:
            'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        tokenType: 'bearer',
      );
    }

    try {
      final response = await dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      final payload = _extractPayload(
        response,
        fallbackMessage: 'Login failed',
      );
      return AuthResponseModel.fromJson(payload);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Login failed');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        AppConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final payload = _extractPayload(
        response,
        fallbackMessage: 'Token refresh failed',
      );
      return AuthResponseModel.fromJson(payload);
    } on DioException catch (e) {
      throw _handleDioException(e, fallbackMessage: 'Token refresh failed');
    }
  }

  Map<String, dynamic> _extractPayload(
    Response<dynamic> response, {
    required String fallbackMessage,
  }) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ServerException('Invalid response format');
    }

    final success = data['success'] == true;
    final statusCode = response.statusCode ?? 500;
    if (statusCode >= 200 && statusCode < 300 && success) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      throw ServerException('Invalid response data');
    }

    final message = data['message']?.toString() ?? fallbackMessage;
    final code = data['code'] is int ? data['code'] as int : statusCode;
    throw ServerException(message, code: code);
  }

  ServerException _handleDioException(
    DioException exception, {
    required String fallbackMessage,
  }) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString() ??
          data['detail']?.toString() ??
          fallbackMessage;
      final code =
          data['code'] is int ? data['code'] as int : exception.response?.statusCode ?? 500;
      return ServerException(message, code: code);
    }
    return ServerException(
      fallbackMessage,
      code: exception.response?.statusCode ?? 500,
    );
  }
}
