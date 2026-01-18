import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.avatarUrl,
    super.subscriptionType,
    super.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionType: _parseSubscriptionType(json['subscription_type']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static SubscriptionType _parseSubscriptionType(dynamic value) {
    if (value == null) return SubscriptionType.free;
    switch (value.toString().toLowerCase()) {
      case 'premium':
        return SubscriptionType.premium;
      case 'pro':
        return SubscriptionType.pro;
      default:
        return SubscriptionType.free;
    }
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
      createdAt: profile.createdAt,
    );
  }
}





