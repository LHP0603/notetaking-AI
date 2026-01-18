import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

class NetworkClient {
  late final Dio _dio;
  final AuthLocalDataSource? authLocalDataSource;

  NetworkClient({this.authLocalDataSource}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectionTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if available
          final skipAuth = options.extra['skipAuth'] == true;
          if (!skipAuth && authLocalDataSource != null) {
            final token = await authLocalDataSource!.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle 401 errors by attempting token refresh
          if (error.response?.statusCode == 401 &&
              authLocalDataSource != null) {
            final isRefreshRequest =
                error.requestOptions.path == AppConstants.refreshTokenEndpoint;
            if (isRefreshRequest) {
              await authLocalDataSource!.clearCache();
              return handler.next(error);
            }

            final refreshToken = await authLocalDataSource!.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Attempt to refresh token
                final response = await _dio.post(
                  AppConstants.refreshTokenEndpoint,
                  data: {'refresh_token': refreshToken},
                  options: Options(
                    extra: {'skipAuth': true},
                  ),
                );

                final data = response.data;
                if (response.statusCode == 200 &&
                    data is Map<String, dynamic> &&
                    data['success'] == true &&
                    data['data'] is Map<String, dynamic>) {
                  final tokenData = data['data'] as Map<String, dynamic>;
                  final newAccessToken = tokenData['access_token'];
                  final newRefreshToken = tokenData['refresh_token'];

                  if (newAccessToken is String &&
                      newRefreshToken is String) {
                    // Save new tokens
                    await authLocalDataSource!.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    // Retry original request with new token
                    error.requestOptions.headers['Authorization'] =
                        'Bearer $newAccessToken';
                    final retryResponse =
                        await _dio.fetch(error.requestOptions);
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (e) {
                // Token refresh failed, clear tokens
                await authLocalDataSource!.clearCache();
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
