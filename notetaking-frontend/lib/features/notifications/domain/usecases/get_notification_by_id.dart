import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationById
    implements UseCase<Either<Failure, Notification>, GetNotificationByIdParams> {
  final NotificationRepository repository;

  GetNotificationById(this.repository);

  @override
  Future<Either<Failure, Notification>> call(
    GetNotificationByIdParams params,
  ) async {
    return await repository.getNotificationById(params.id);
  }
}

class GetNotificationByIdParams extends Equatable {
  final int id;

  const GetNotificationByIdParams(this.id);

  @override
  List<Object?> get props => [id];
}
