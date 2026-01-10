import 'dart:convert';
import '../../domain/entities/audit_log.dart';

class AuditLogModel extends AuditLog {
  const AuditLogModel({
    required int logId,
    required String userId,
    String? userEmail,
    required String action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    required DateTime createdAt,
  }) : super(
         logId: logId,
         userId: userId,
         userEmail: userEmail,
         action: action,
         resourceType: resourceType,
         resourceId: resourceId,
         details: details,
         ipAddress: ipAddress,
         userAgent: userAgent,
         createdAt: createdAt,
       );

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    // Parse details - can be a JSON string or Map
    Map<String, dynamic>? details;
    if (json['details'] is String) {
      // If it's a JSON string, parse it
      try {
        details = jsonDecode(json['details'] as String) as Map<String, dynamic>;
      } catch (e) {
        details = null;
      }
    } else if (json['details'] is Map) {
      // If it's already a Map, use it directly
      details = json['details'] as Map<String, dynamic>;
    }

    return AuditLogModel(
      logId: (json['log_id'] as int?) ?? 0,
      userId: (json['user_id'] as String?) ?? 'System',
      userEmail: json['user_email'] as String?,
      action: (json['action'] as String?) ?? 'Unknown',
      resourceType: json['resource_type'] as String?,
      resourceId: json['resource_id'] as String?,
      details: details,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'user_id': userId,
      'user_email': userEmail,
      'action': action,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'details': details != null ? jsonEncode(details) : null,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      logId: entity.logId,
      userId: entity.userId,
      userEmail: entity.userEmail,
      action: entity.action,
      resourceType: entity.resourceType,
      resourceId: entity.resourceId,
      details: entity.details,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      createdAt: entity.createdAt,
    );
  }
}
