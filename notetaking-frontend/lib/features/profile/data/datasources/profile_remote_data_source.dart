import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String accessToken);
  Future<UserProfileModel> updateProfile({
    required String accessToken,
    String? name,
    String? email,
    String? avatarUrl,
  });
  Future<String> updateAvatar({
    required String accessToken,
    required String imagePath,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserProfileModel> getProfile(String accessToken) async {
    try {
      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to get profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Session expired');
      }
      throw ServerException('Failed to get profile: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) rethrow;
      throw ServerException('Failed to get profile: $e');
    }
  }

  @override
  Future<UserProfileModel> updateProfile({
    required String accessToken,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await dio.put(
        '/auth/profile',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to update profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Session expired');
      }
      throw ServerException('Failed to update profile: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) rethrow;
      throw ServerException('Failed to update profile: $e');
    }
  }

  @override
  Future<String> updateAvatar({
    required String accessToken,
    required String imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imagePath),
      });

      final response = await dio.post(
        '/auth/avatar',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return response.data['avatar_url'] as String;
      } else {
        throw ServerException('Failed to update avatar: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Session expired');
      }
      throw ServerException('Failed to update avatar: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) rethrow;
      throw ServerException('Failed to update avatar: $e');
    }
  }
}





