import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  const LoadProfile();
}

class UpdateProfileRequested extends ProfileEvent {
  final String? name;
  final String? email;

  const UpdateProfileRequested({this.name, this.email});

  @override
  List<Object?> get props => [name, email];
}

class UpdateAvatarRequested extends ProfileEvent {
  final String imagePath;

  const UpdateAvatarRequested({required this.imagePath});

  @override
  List<Object?> get props => [imagePath];
}

class LogoutRequested extends ProfileEvent {
  const LogoutRequested();
}





