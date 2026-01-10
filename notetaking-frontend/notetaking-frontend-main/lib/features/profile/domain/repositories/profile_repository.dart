import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  /// Get the current user's profile
  Future<Either<Failure, UserProfile>> getProfile();

  /// Update the user's profile
  Future<Either<Failure, UserProfile>> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? avatarUrl,
  });

  /// Update the user's avatar
  Future<Either<Failure, String>> updateAvatar(String imagePath);

  /// Update the user's password
  Future<Either<Failure, void>> updatePassword(String newPassword);

  /// Logout the current user
  Future<Either<Failure, void>> logout();
}
