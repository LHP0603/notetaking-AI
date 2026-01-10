import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsersEvent extends AdminEvent {
  final String? email;
  final int? tierId;
  final bool? isActive;
  final int? page;

  const LoadUsersEvent({this.email, this.tierId, this.isActive, this.page});
}

class UpdateUserEvent extends AdminEvent {
  final String userId;
  final int? tierId;
  final String? role;
  final bool? isActive;

  const UpdateUserEvent({
    required this.userId,
    this.tierId,
    this.role,
    this.isActive,
  });
}

class LoadTiersEvent extends AdminEvent {}

class CreateTierEvent extends AdminEvent {
  final String name;
  final double monthlyPrice;
  final int maxStorageMb;
  final int maxAiMinutesMonthly;

  const CreateTierEvent({
    required this.name,
    required this.monthlyPrice,
    required this.maxStorageMb,
    required this.maxAiMinutesMonthly,
  });
}

class UpdateTierEvent extends AdminEvent {
  final int tierId;
  final String? name;
  final double? monthlyPrice;
  final int? maxStorageMb;
  final int? maxAiMinutesMonthly;

  const UpdateTierEvent({
    required this.tierId,
    this.name,
    this.monthlyPrice,
    this.maxStorageMb,
    this.maxAiMinutesMonthly,
  });
}

class DeleteTierEvent extends AdminEvent {
  final int tierId;
  const DeleteTierEvent(this.tierId);
}

class LoadAuditLogsEvent extends AdminEvent {
  final String? userId;
  final String? action;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? page;

  const LoadAuditLogsEvent({
    this.userId,
    this.action,
    this.startDate,
    this.endDate,
    this.page,
  });
}

class ResetAdminEvent extends AdminEvent {}
