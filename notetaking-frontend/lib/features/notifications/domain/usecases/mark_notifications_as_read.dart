import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationsAsRead
    implements UseCase<Either<Failure, int>, MarkNotificationsAsReadParams> {
  final NotificationRepository repository;

  MarkNotificationsAsRead(this.repository);

  @override
  Future<Either<Failure, int>> call(
    MarkNotificationsAsReadParams params,
  ) async {
    return await repository.markAsRead(params.notificationIds);
  }
}

class MarkNotificationsAsReadParams extends Equatable {
  final List<int> notificationIds;

  const MarkNotificationsAsReadParams(this.notificationIds);

  @override
  List<Object?> get props => [notificationIds];
}
