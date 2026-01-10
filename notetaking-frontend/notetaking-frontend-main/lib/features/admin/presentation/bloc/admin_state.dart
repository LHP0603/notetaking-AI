import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object> get props => [message];
}

class UsersLoaded extends AdminState {
  final List<User> users;
  const UsersLoaded(this.users);
  @override
  List<Object> get props => [users];
}

class TiersLoaded extends AdminState {
  final List<Tier> tiers;
  const TiersLoaded(this.tiers);
  @override
  List<Object> get props => [tiers];
}

class AuditLogsLoaded extends AdminState {
  final List<AuditLog> logs;
  const AuditLogsLoaded(this.logs);
  @override
  List<Object> get props => [logs];
}

class ActionSuccess extends AdminState {
  final String message;
  const ActionSuccess(this.message);
  @override
  List<Object> get props => [message];
}
