import 'package:equatable/equatable.dart';

enum UserRole {
  user('USER'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value.toUpperCase(),
      orElse: () => UserRole.user,
    );
  }
}

class User extends Equatable {
  final String id; 
  final String email; 
  final String fullName;
  final int tierId; 
  final UserRole role; 
  final bool isActive; 
  final double storageUsedMb; 
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.tierId,
    required this.role,
    required this.isActive,
    required this.storageUsedMb,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    tierId,
    role,
    isActive,
    storageUsedMb,
    createdAt,
  ];
}
