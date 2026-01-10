import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository adminRepository;

  AdminBloc({required this.adminRepository}) : super(AdminInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<UpdateUserEvent>(_onUpdateUser);
    on<LoadTiersEvent>(_onLoadTiers);
    on<CreateTierEvent>(_onCreateTier);
    on<UpdateTierEvent>(_onUpdateTier);
    on<DeleteTierEvent>(_onDeleteTier);
    on<LoadAuditLogsEvent>(_onLoadAuditLogs);
    on<ResetAdminEvent>(_onReset);
  }

  void _onReset(ResetAdminEvent event, Emitter<AdminState> emit) {
    emit(AdminInitial());
  }

  void _onLoadUsers(LoadUsersEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await adminRepository.getUsers(
      email: event.email,
      tierId: event.tierId,
      isActive: event.isActive,
      page: event.page,
    );
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (users) => emit(UsersLoaded(users)),
    );
  }

  void _onUpdateUser(UpdateUserEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await adminRepository.updateUser(
      event.userId,
      tierId: event.tierId,
      role: event.role,
      isActive: event.isActive,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (user) {
      emit(const ActionSuccess('User updated successfully'));
      // Reload users to reflect changes
      add(const LoadUsersEvent());
    });
  }

  void _onLoadTiers(LoadTiersEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await adminRepository.getTiers();
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (tiers) => emit(TiersLoaded(tiers)),
    );
  }

  void _onCreateTier(CreateTierEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await adminRepository.createTier(
      name: event.name,
      monthlyPrice: event.monthlyPrice,
      maxStorageMb: event.maxStorageMb,
      maxAiMinutesMonthly: event.maxAiMinutesMonthly,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (tier) {
      emit(const ActionSuccess('Tier created successfully'));
      add(LoadTiersEvent());
    });
  }

  void _onUpdateTier(UpdateTierEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await adminRepository.updateTier(
      event.tierId,
      name: event.name,
      monthlyPrice: event.monthlyPrice,
      maxStorageMb: event.maxStorageMb,
      maxAiMinutesMonthly: event.maxAiMinutesMonthly,
    );
    result.fold((failure) => emit(AdminError(failure.message)), (tier) {
      emit(const ActionSuccess('Tier updated successfully'));
      add(LoadTiersEvent());
    });
  }

  void _onDeleteTier(DeleteTierEvent event, Emitter<AdminState> emit) async {
    emit(AdminLoading());
    final result = await adminRepository.deleteTier(event.tierId);
    result.fold((failure) => emit(AdminError(failure.message)), (_) {
      emit(const ActionSuccess('Tier deleted successfully'));
      add(LoadTiersEvent());
    });
  }

  void _onLoadAuditLogs(
    LoadAuditLogsEvent event,
    Emitter<AdminState> emit,
  ) async {
    emit(AdminLoading());
    final result = await adminRepository.getAuditLogs(
      userId: event.userId,
      action: event.action,
      startDate: event.startDate,
      endDate: event.endDate,
      page: event.page,
    );
    result.fold(
      (failure) => emit(AdminError(failure.message)),
      (logs) => emit(AuditLogsLoaded(logs)),
    );
  }
}
