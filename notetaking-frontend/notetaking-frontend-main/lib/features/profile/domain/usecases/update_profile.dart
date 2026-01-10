import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<Either<Failure, UserProfile>> call({
    required String userId,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    return await repository.updateProfile(
      userId: userId,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
    );
  }
}
