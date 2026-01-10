import 'package:equatable/equatable.dart';

class AuditLog extends Equatable {
  final int logId; 
  final String userId; 
  final String? userEmail;
  final String action; 
  final String? resourceType; 
  final String? resourceId; 
  final Map<String, dynamic>? details; 
  final String? ipAddress; 
  final String? userAgent; 
  final DateTime createdAt; 

  const AuditLog({
    required this.logId,
    required this.userId,
    this.userEmail,
    required this.action,
    this.resourceType,
    this.resourceId,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  AuditLog copyWith({
    int? logId,
    String? userId,
    String? userEmail,
    String? action,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
  }) {
    return AuditLog(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      details: details ?? this.details,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    logId,
    userId,
    userEmail,
    action,
    resourceType,
    resourceId,
    details,
    ipAddress,
    userAgent,
    createdAt,
  ];
}
