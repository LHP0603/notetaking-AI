import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/supabase/supabase_client.dart' as app_supabase;
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserProfileModel> getProfile(String accessToken);
  Future<UserProfileModel> updateProfile({
    required String accessToken,
    required String userId,
    String? name,
    String? email,
    String? avatarUrl,
  });
  Future<String> updateAvatar({
    required String accessToken,
    required String imagePath,
  });
  Future<void> updatePassword({required String newPassword});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserProfileModel> getProfile(String accessToken) async {
    try {
      final response = await dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to get profile: ${response.statusMessage}',
        );
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
    required String userId,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['full_name'] = name;
      if (email != null) data['email'] = email;

      final response = await dio.put(
        '/users/$userId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to update profile: ${response.statusMessage}',
        );
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
        throw ServerException(
          'Failed to update avatar: ${response.statusMessage}',
        );
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

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await app_supabase.SupabaseClient.instance.supabase.client.auth
          .updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw ServerException('Failed to update password: $e');
    }
  }
}
