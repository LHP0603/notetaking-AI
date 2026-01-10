import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_profile_model.dart';

abstract class ProfileLocalDataSource {
  Future<UserProfileModel?> getCachedProfile();
  Future<void> cacheProfile(UserProfileModel profile);
  Future<void> clearProfile();
  Future<void> clearAllData();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _profileKey = 'cached_profile';

  ProfileLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<UserProfileModel?> getCachedProfile() async {
    final jsonString = sharedPreferences.getString(_profileKey);
    if (jsonString != null) {
      return UserProfileModel.fromJson(json.decode(jsonString));
    }
    return null;
  }

  @override
  Future<void> cacheProfile(UserProfileModel profile) async {
    await sharedPreferences.setString(
      _profileKey,
      json.encode(profile.toJson()),
    );
  }

  @override
  Future<void> clearProfile() async {
    await sharedPreferences.remove(_profileKey);
  }

  @override
  Future<void> clearAllData() async {
    await sharedPreferences.remove(_profileKey);
    await sharedPreferences.remove(AppConstants.accessTokenKey);
    await sharedPreferences.remove(AppConstants.refreshTokenKey);
    await sharedPreferences.remove(AppConstants.userDataKey);
  }
}












