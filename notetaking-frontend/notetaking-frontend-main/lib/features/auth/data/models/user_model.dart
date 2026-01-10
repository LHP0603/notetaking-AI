import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String fullName,
    required int tierId,
    required UserRole role,
    required bool isActive,
    required double storageUsedMb,
    required DateTime createdAt,
  }) : super(
         id: id,
         email: email,
         fullName: fullName,
         tierId: tierId,
         role: role,
         isActive: isActive,
         storageUsedMb: storageUsedMb,
         createdAt: createdAt,
       );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] ?? json['id'], // Support both user_id and id
      email: json['email'] as String,
      fullName: (json['full_name'] as String?) ?? 'Unknown',
      tierId: (json['tier_id'] as int?) ?? 0,
      role: UserRole.fromString(json['role'] as String? ?? 'USER'),
      isActive: json['is_active'] as bool? ?? true,
      storageUsedMb: (json['storage_used_mb'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      'full_name': fullName,
      'tier_id': tierId,
      'role': role.value,
      'is_active': isActive,
      'storage_used_mb': storageUsedMb,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
