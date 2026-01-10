import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/admin_repository.dart';
import '../../../auth/domain/entities/user.dart';

class GetUsers {
  final AdminRepository repository;

  GetUsers(this.repository);

  Future<Either<Failure, List<User>>> call({
    String? email,
    int? tierId,
    bool? isActive,
  }) async {
    return await repository.getUsers(
      email: email,
      tierId: tierId,
      isActive: isActive,
    );
  }
}

