import '../../domain/entities/tier.dart';

class TierModel extends Tier {
  const TierModel({
    required int tierId,
    required String name,
    required double maxStorageMb,
    required double maxAiMinutesPerMonth,
    double? pricePerMonth,
    required bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) : super(
         tierId: tierId,
         name: name,
         maxStorageMb: maxStorageMb,
         maxAiMinutesPerMonth: maxAiMinutesPerMonth,
         pricePerMonth: pricePerMonth,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory TierModel.fromJson(Map<String, dynamic> json) {
    return TierModel(
      tierId: json['tier_id'] as int,
      name: json['name'] as String? ?? 'Unknown Tier',
      maxStorageMb: (json['max_storage_mb'] as num?)?.toDouble() ?? 0.0,
      maxAiMinutesPerMonth:
          (json['max_ai_minutes_per_month'] as num?)?.toDouble() ?? 0.0,
      pricePerMonth: (json['price_per_month'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier_id': tierId,
      'name': name,
      'max_storage_mb': maxStorageMb,
      'max_ai_minutes_per_month': maxAiMinutesPerMonth,
      'price_per_month': pricePerMonth,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory TierModel.fromEntity(Tier entity) {
    return TierModel(
      tierId: entity.tierId,
      name: entity.name,
      maxStorageMb: entity.maxStorageMb,
      maxAiMinutesPerMonth: entity.maxAiMinutesPerMonth,
      pricePerMonth: entity.pricePerMonth,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
