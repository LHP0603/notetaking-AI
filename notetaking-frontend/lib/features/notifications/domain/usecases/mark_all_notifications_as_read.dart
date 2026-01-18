import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkAllNotificationsAsRead
    implements UseCase<Either<Failure, int>, NoParams> {
  final NotificationRepository repository;

  MarkAllNotificationsAsRead(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) async {
    return await repository.markAllAsRead();
  }
}
