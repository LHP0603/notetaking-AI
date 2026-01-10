import '../../domain/entities/user_profile.dart';
import '../../../auth/domain/entities/user.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.avatarUrl,
    super.subscriptionType,
    super.role,
    super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['user_id'] as String,
      name: (json['full_name'] as String?) ?? 'Guest',
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionType: _parseSubscriptionTypeFromTier(json['tier_id']),
      role: _parseRole(json['role']),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
    );
  }

  static SubscriptionType _parseSubscriptionTypeFromTier(dynamic tierId) {
    if (tierId == null) return SubscriptionType.free;
    if (tierId is int && tierId > 0) {
      return SubscriptionType.premium;
    }
    return SubscriptionType.free;
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.user;
    return UserRole.fromString(role.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'subscription_type': subscriptionType.name,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      avatarUrl: profile.avatarUrl,
      subscriptionType: profile.subscriptionType,
      role: profile.role,
      createdAt: profile.createdAt,
    );
  }
}
