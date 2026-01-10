import 'dart:convert';
import 'dart:developer'; 
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, String>> login(String email, String password);
  Future<Map<String, String>> signup(
    String name,
    String email,
    String password,
  );
  Future<Map<String, String>> refresh(String refreshToken);
  Future<Map<String, dynamic>> getCurrentUser(String accessToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  // Demo/Test account 
  static const String _demoEmail = 'test@voicely.com';
  static const String _demoPassword = 'password123';
  static const bool _enableDemoAccount = false; 

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, String>> login(String email, String password) async {
    // Check for demo account login
    if (_enableDemoAccount &&
        email == _demoEmail &&
        password == _demoPassword) {
      log('Demo account login successful');
      return {
        'access_token':
            'demo_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token':
            'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        'token_type': 'Bearer',
      };
    }

    try {
      log('Attempting login with email: $email'); 
      final response = await dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      log('Login response: ${response.data}'); // Log response details

      if (response.statusCode == 200) {
        
        final responseData =
            response.data is Map
                ? Map<String, dynamic>.from(response.data)
                : <String, dynamic>{};

        final accessToken = responseData['access_token'];
        final refreshToken = responseData['refresh_token'];
        final tokenType = responseData['token_type'] ?? 'Bearer';

        if (accessToken != null) {
          return {
            'access_token': accessToken,
            'refresh_token': refreshToken ?? '',
            'token_type': tokenType,
          };
        }

        throw ServerException('Login response missing access_token');
      } else {
        throw ServerException('Failed to login: ${response.statusMessage}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          log(
            'DioException response: ${e.response!.data}',
          ); // Log error response
          final statusCode = e.response!.statusCode;

          // Extract error message from response
          String errorMessage = 'Unknown error';
          if (e.response!.data is Map) {
            errorMessage =
                e.response!.data['detail'] ??
                e.response!.data['message'] ??
                e.response!.data['error'] ??
                e.response!.data['msg'] ??
                'Request failed';

            // Check for Supabase-specific errors
            final errorDetail = e.response!.data['detail'] ?? '';
            if (errorDetail.toString().contains('Email not confirmed') ||
                errorDetail.toString().contains('email_not_confirmed')) {
              throw ValidationException(
                'Please check your email and confirm your account before logging in.',
              );
            }
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
            if (errorMessage.contains('Email not confirmed') ||
                errorMessage.contains('email_not_confirmed')) {
              throw ValidationException(
                'Please check your email and confirm your account before logging in.',
              );
            }
          }

          if (statusCode == 401) {
            throw UnauthorizedException(errorMessage);
          } else if (statusCode == 400 || statusCode == 422) {
            
            throw ValidationException(errorMessage);
          } else if (statusCode == 500) {
            throw ServerException('Server error: $errorMessage');
          } else {
            throw ServerException(
              'Request failed (${statusCode}): $errorMessage',
            );
          }
        } else {
          
          log('DioException without response: ${e.message}');
          throw ServerException(
            'Network error: ${e.message ?? 'Unable to connect to server'}',
          );
        }
      } else if (e is ServerException ||
          e is ValidationException ||
          e is UnauthorizedException) {
        rethrow;
      } else {
        log(
          'Login failed with unexpected error: ${e.toString()}',
        ); // Log general error
        throw ServerException('Login failed: ${e.toString()}');
      }
    }
  }

  @override
  Future<Map<String, String>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      log('Attempting signup with email: $email'); 
      final requestData = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (name.isNotEmpty) {
        requestData['name'] = name;
      }

      log('Signup request data: $requestData'); 

      final response = await dio.post(
        AppConstants.signupEndpoint,
        data: requestData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      log('Signup response status: ${response.statusCode}'); 
      log(
        'Signup response data type: ${response.data.runtimeType}',
      ); // Log data type
      log('Signup response data: ${response.data}'); 

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle different response structures
        Map<String, dynamic> responseData;

        if (response.data is Map) {
          responseData = Map<String, dynamic>.from(response.data);
        } else if (response.data is String) {
          // Try to parse JSON string
          try {
            responseData = Map<String, dynamic>.from(
              jsonDecode(response.data as String),
            );
          } catch (e) {
            log('Failed to parse response as JSON: $e');
            throw ServerException('Invalid response format from server');
          }
        } else {
          log('Unexpected response data type: ${response.data.runtimeType}');
          throw ServerException('Unexpected response format from server');
        }
        final accessToken = responseData['access_token'];
        final refreshToken = responseData['refresh_token'];
        final tokenType = responseData['token_type'] ?? 'Bearer';

        if (accessToken != null) {
          return {
            'access_token': accessToken,
            'refresh_token': refreshToken ?? '',
            'token_type': tokenType,
          };
        } else {
          log(
            'Signup response missing access_token. Full response: $responseData',
          );

          // Extract email from response or request
          String? userEmail;
          if (responseData['user'] != null && responseData['user'] is Map) {
            final userObj = responseData['user'] as Map;
            userEmail = userObj['email']?.toString();
          }
          userEmail ??= requestData['email']?.toString();

          // If we have an email, throw email confirmation exception
          if (userEmail != null) {
            throw EmailConfirmationRequiredException(
              userEmail,
              'Please check your email and confirm your account.',
            );
          } else {
            throw ServerException(
              'Signup succeeded but backend did not return access token. '
              'You may need to check your email for confirmation. '
              'Response fields: ${responseData.keys.join(", ")}',
            );
          }
        }
      } else {
        throw ServerException(
          'Failed to sign up: ${response.statusMessage} (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response != null) {
          log(
            'DioException response: ${e.response!.data}',
          ); // Log error response
          final statusCode = e.response!.statusCode;

          String errorMessage = 'Unknown error';
          if (e.response!.data is Map) {
            final detail = e.response!.data['detail'];
            if (detail is List && detail.isNotEmpty) {
              final errors = detail
                  .map((e) {
                    if (e is Map) {
                      final loc =
                          e['loc'] is List ? e['loc'].join('.') : 'field';
                      final msg = e['msg'] ?? e['type'] ?? 'validation error';
                      return '$loc: $msg';
                    }
                    return e.toString();
                  })
                  .join(', ');
              errorMessage = errors;
            } else if (detail is String) {
              errorMessage = detail;
            } else {
              errorMessage =
                  detail?.toString() ??
                  e.response!.data['message'] ??
                  e.response!.data['error'] ??
                  e.response!.data['msg'] ??
                  'Server error occurred';
            }

            // Check for Supabase-specific errors
            final errorDetailStr = errorMessage.toLowerCase();
            if (errorDetailStr.contains('email not confirmed') ||
                errorDetailStr.contains('email_not_confirmed')) {
              throw ValidationException(
                'Please check your email and confirm your account.',
              );
            }
          } else if (e.response!.data is String) {
            errorMessage = e.response!.data;
            if (errorMessage.toLowerCase().contains('email not confirmed') ||
                errorMessage.toLowerCase().contains('email_not_confirmed')) {
              throw ValidationException(
                'Please check your email and confirm your account.',
              );
            }
          }

          if (statusCode == 400 || statusCode == 422) {
            throw ValidationException(errorMessage);
          } else if (statusCode == 429) {
            // Too Many Requests - rate limiting
            throw ValidationException(errorMessage);
          } else if (statusCode == 500) {
            throw ServerException('Server error: $errorMessage');
          } else {
            throw ServerException(
              'Request failed (${statusCode}): $errorMessage',
            );
          }
        } else {
          // No response - network or connection error
          log('DioException without response: ${e.message}');
          throw ServerException(
            'Network error: ${e.message ?? 'Unable to connect to server'}',
          );
        }
      } else if (e is ServerException || e is ValidationException) {
        // Re-throw if already the right exception type
        rethrow;
      } else {
        log(
          'Signup failed with unexpected error: ${e.toString()}',
        ); // Log general error
        throw ServerException('Signup failed: ${e.toString()}');
      }
    }
  }

  @override
  Future<Map<String, String>> refresh(String refreshToken) async {
    try {
      final response = await dio.post(
        AppConstants.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        return {
          'access_token': response.data['access_token'],
          'refresh_token': response.data['refresh_token'],
          'token_type': response.data['token_type'],
        };
      } else {
        throw ServerException(
          'Failed to refresh token: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        if (e.response!.statusCode == 400) {
          throw ValidationException(
            e.response!.data['detail'] ?? 'Validation error',
          );
        }
      }
      throw ServerException('Token refresh failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    // Check for demo account token
    if (_enableDemoAccount && accessToken.startsWith('demo_access_token_')) {
      log('Returning demo user data');
      return {
        'user_id': 'demo_user_001',
        'email': _demoEmail,
        'full_name': 'Demo User',
        'tier_id': 1,
        'role': 'USER',
        'is_active': true,
        'storage_used_mb': 0.0,
        'created_at': DateTime.now().toIso8601String(),
      };
    }

    try {
      final response = await dio.get(
        AppConstants.authMeEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException(
          'Failed to fetch user info: ${response.statusMessage}',
        );
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        if (e.response!.statusCode == 401) {
          throw UnauthorizedException('Invalid or expired token');
        }
      }
      throw ServerException('Fetching user info failed: ${e.toString()}');
    }
  }
}
