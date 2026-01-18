import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/notification_list_response.dart';
import '../repositories/notification_repository.dart';

class GetNotifications implements UseCase<Either<Failure, NotificationListResponse>, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  @override
  Future<Either<Failure, NotificationListResponse>> call(
    GetNotificationsParams params,
  ) async {
    return await repository.getNotifications(
      isRead: params.isRead,
      notificationType: params.notificationType,
      skip: params.skip,
      limit: params.limit,
    );
  }
}

class GetNotificationsParams extends Equatable {
  final bool? isRead;
  final String? notificationType;
  final int skip;
  final int limit;

  const GetNotificationsParams({
    this.isRead,
    this.notificationType,
    this.skip = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [isRead, notificationType, skip, limit];
}
