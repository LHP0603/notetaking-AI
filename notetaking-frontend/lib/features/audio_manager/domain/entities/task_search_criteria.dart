import 'package:equatable/equatable.dart';

class TaskSearchCriteria extends Equatable {
  final bool activeOnly;
  final String order;
  final int page;
  final int pageSize;
  final String taskType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? status;

  const TaskSearchCriteria({
    this.activeOnly = true,
    this.order = 'DESC',
    this.page = 1,
    this.pageSize = 100,
    required this.taskType,
    this.fromDate,
    this.toDate,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'active_only': activeOnly,
      'order': order,
      'page': page,
      'page_size': pageSize,
      'task_type': taskType,
    };

    if (fromDate != null) {
      json['from_date'] = fromDate!.toIso8601String();
    }
    if (toDate != null) {
      json['to_date'] = toDate!.toIso8601String();
    }
    if (status != null) {
      json['status'] = status;
    }

    return json;
  }

  @override
  List<Object?> get props => [
    activeOnly,
    order,
    page,
    pageSize,
    taskType,
    fromDate,
    toDate,
    status,
  ];
}
