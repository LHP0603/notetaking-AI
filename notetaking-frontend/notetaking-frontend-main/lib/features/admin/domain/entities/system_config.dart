import 'package:equatable/equatable.dart';

class SystemConfig extends Equatable {
  final String configKey; 
  final String configValue; 
  final String? description; 
  final bool isSensitive; 
  final DateTime updatedAt; 
  final String? updatedBy; 

  const SystemConfig({
    required this.configKey,
    required this.configValue,
    this.description,
    required this.isSensitive,
    required this.updatedAt,
    this.updatedBy,
  });

  SystemConfig copyWith({
    String? configKey,
    String? configValue,
    String? description,
    bool? isSensitive,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return SystemConfig(
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      description: description ?? this.description,
      isSensitive: isSensitive ?? this.isSensitive,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  List<Object?> get props => [
    configKey,
    configValue,
    description,
    isSensitive,
    updatedAt,
    updatedBy,
  ];
}

