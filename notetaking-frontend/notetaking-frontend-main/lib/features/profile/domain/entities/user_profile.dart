import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

enum SubscriptionType { free, premium, pro }

class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final SubscriptionType subscriptionType;
  final UserRole role;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.subscriptionType = SubscriptionType.free,
    this.role = UserRole.user,
    this.createdAt,
  });

  String get subscriptionLabel {
    switch (subscriptionType) {
      case SubscriptionType.premium:
        return 'Premium';
      case SubscriptionType.pro:
        return 'Pro';
      case SubscriptionType.free:
        return 'Free';
    }
  }

  bool get isPremium => subscriptionType != SubscriptionType.free;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    avatarUrl,
    subscriptionType,
    role,
    createdAt,
  ];
}
