import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final Logout logout;
  final ProfileRepository repository;

  ProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.logout,
    required this.repository,
  }) : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<UpdateAvatarRequested>(_onUpdateAvatar);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile();

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentProfile: currentState.profile));

      final result = await updateProfile(
        name: event.name,
        email: event.email,
      );

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          previousProfile: currentState.profile,
        )),
        (profile) => emit(ProfileLoaded(profile: profile)),
      );
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatarRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      emit(ProfileUpdating(currentProfile: currentState.profile));

      final result = await repository.updateAvatar(event.imagePath);

      result.fold(
        (failure) => emit(ProfileError(
          message: failure.message,
          previousProfile: currentState.profile,
        )),
        (avatarUrl) {
          // Reload profile to get updated data
          add(const LoadProfile());
        },
      );
    }
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final result = await logout();

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (_) => emit(const LogoutSuccess()),
    );
  }
}





