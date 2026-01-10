import 'package:equatable/equatable.dart';

class Tier extends Equatable {
  final int tierId; 
  final String name; 
  final double maxStorageMb; 
  final double maxAiMinutesPerMonth; 
  final double? pricePerMonth; 
  final bool isActive; 
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Tier({
    required this.tierId,
    required this.name,
    required this.maxStorageMb,
    required this.maxAiMinutesPerMonth,
    this.pricePerMonth,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  Tier copyWith({
    int? tierId,
    String? name,
    double? maxStorageMb,
    double? maxAiMinutesPerMonth,
    double? pricePerMonth,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tier(
      tierId: tierId ?? this.tierId,
      name: name ?? this.name,
      maxStorageMb: maxStorageMb ?? this.maxStorageMb,
      maxAiMinutesPerMonth: maxAiMinutesPerMonth ?? this.maxAiMinutesPerMonth,
      pricePerMonth: pricePerMonth ?? this.pricePerMonth,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    tierId,
    name,
    maxStorageMb,
    maxAiMinutesPerMonth,
    pricePerMonth,
    isActive,
    createdAt,
    updatedAt,
  ];
}

