import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_list_response.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  @override
  Future<Either<Failure, NotificationListResponse>> getNotifications({
    bool? isRead,
    String? notificationType,
    int skip = 0,
    int limit = 20,
  }) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view notifications'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getNotifications(
        isRead: isRead,
        notificationType: notificationType,
        skip: skip,
        limit: limit,
      );
      return Right(response);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view notifications'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final count = await remoteDataSource.getUnreadCount();
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Notification>> getNotificationById(int id) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to view notifications'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final notification = await remoteDataSource.getNotificationById(id);
      return Right(notification);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> markAsRead(
    List<int> notificationIds,
  ) async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update notifications'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final updatedCount =
          await remoteDataSource.markAsRead(notificationIds);
      return Right(updatedCount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> markAllAsRead() async {
    final token = await authLocalDataSource.getAccessToken();
    if (token == null) {
      return const Left(UnauthorizedFailure('Please login to update notifications'));
    }

    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final updatedCount = await remoteDataSource.markAllAsRead();
      return Right(updatedCount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    }
  }
}
