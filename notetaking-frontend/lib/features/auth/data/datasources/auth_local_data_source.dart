import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<void> cacheUser(UserModel user);
  Future<void> clearCache();
  Future<String?> getAccessToken();
  Future<void> setAccessToken(String token);
  Future<String?> getRefreshToken();
  Future<void> setRefreshToken(String token);
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clearTokens();
  Future<void> cacheTokens(Map<String, String> tokens);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.secureStorage,
  });

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final jsonString = sharedPreferences.getString(AppConstants.userDataKey);
      if (jsonString != null) {
        return UserModel.fromJson(json.decode(jsonString));
      }
      return null;
    } catch (e) {
      throw CacheException('Failed to get cached user');
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await sharedPreferences.setString(
        AppConstants.userDataKey,
        json.encode(user.toJson()),
      );
    } catch (e) {
      throw CacheException('Failed to cache user');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(AppConstants.userDataKey);
      await sharedPreferences.remove(AppConstants.accessTokenKey);
      await sharedPreferences.remove(AppConstants.refreshTokenKey);
      await clearTokens();
    } catch (e) {
      throw CacheException('Failed to clear cache');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    final token = await secureStorage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      return token;
    }

    final legacyToken = sharedPreferences.getString(
      AppConstants.accessTokenKey,
    );
    if (legacyToken != null) {
      await secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: legacyToken,
      );
      await sharedPreferences.remove(AppConstants.accessTokenKey);
    }
    return legacyToken;
  }

  @override
  Future<void> setAccessToken(String token) async {
    await secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  @override
  Future<String?> getRefreshToken() async {
    final token = await secureStorage.read(key: AppConstants.refreshTokenKey);
    if (token != null) {
      return token;
    }

    final legacyToken = sharedPreferences.getString(
      AppConstants.refreshTokenKey,
    );
    if (legacyToken != null) {
      await secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: legacyToken,
      );
      await sharedPreferences.remove(AppConstants.refreshTokenKey);
    }
    return legacyToken;
  }

  @override
  Future<void> setRefreshToken(String token) async {
    await secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
    );
  }

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
  Future<void> clearTokens() async {
    await Future.wait([
      secureStorage.delete(key: AppConstants.accessTokenKey),
      secureStorage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  @override
  Future<void> cacheTokens(Map<String, String> tokens) async {
    try {
      final accessToken = tokens['access_token'];
      final refreshToken = tokens['refresh_token'];
      if (accessToken == null || refreshToken == null) {
        throw CacheException('Missing token values');
      }
      await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    } catch (e) {
      throw CacheException('Failed to cache tokens');
    }
  }
}
