import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  Future<void> cacheTokens(Map<String, String> tokens);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

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
    } catch (e) {
      throw CacheException('Failed to clear cache');
    }
  }

  @override
  Future<String?> getAccessToken() async {
    return sharedPreferences.getString(AppConstants.accessTokenKey);
  }

  @override
  Future<void> setAccessToken(String token) async {
    await sharedPreferences.setString(AppConstants.accessTokenKey, token);
  }

  @override
  Future<String?> getRefreshToken() async {
    return sharedPreferences.getString(AppConstants.refreshTokenKey);
  }

  @override
  Future<void> setRefreshToken(String token) async {
    await sharedPreferences.setString(AppConstants.refreshTokenKey, token);
  }

  @override
  Future<void> cacheTokens(Map<String, String> tokens) async {
    try {
      await sharedPreferences.setString(
        AppConstants.accessTokenKey,
        tokens['access_token']!,
      );
      await sharedPreferences.setString(
        AppConstants.refreshTokenKey,
        tokens['refresh_token']!,
      );
    } catch (e) {
      throw CacheException('Failed to cache tokens');
    }
  }
}
