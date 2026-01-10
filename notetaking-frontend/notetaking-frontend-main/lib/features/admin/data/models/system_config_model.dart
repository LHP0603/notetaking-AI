import '../../domain/entities/system_config.dart';

class SystemConfigModel extends SystemConfig {
  const SystemConfigModel({
    required String configKey,
    required String configValue,
    String? description,
    required bool isSensitive,
    required DateTime updatedAt,
    String? updatedBy,
  }) : super(
         configKey: configKey,
         configValue: configValue,
         description: description,
         isSensitive: isSensitive,
         updatedAt: updatedAt,
         updatedBy: updatedBy,
       );

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      configKey: json['config_key'] as String,
      configValue: json['config_value'] as String,
      description: json['description'] as String?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'config_key': configKey,
      'config_value': configValue,
      'description': description,
      'is_sensitive': isSensitive,
      'updated_at': updatedAt.toIso8601String(),
      'updated_by': updatedBy,
    };
  }

  factory SystemConfigModel.fromEntity(SystemConfig entity) {
    return SystemConfigModel(
      configKey: entity.configKey,
      configValue: entity.configValue,
      description: entity.description,
      isSensitive: entity.isSensitive,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }
}

