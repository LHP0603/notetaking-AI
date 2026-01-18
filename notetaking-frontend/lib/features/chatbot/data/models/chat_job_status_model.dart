import 'chat_message_model.dart';

class ChatJobStatusModel {
  final String jobId;
  final String status;
  final ChatMessageModel? message;

  const ChatJobStatusModel({
    required this.jobId,
    required this.status,
    this.message,
  });

  factory ChatJobStatusModel.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    return ChatJobStatusModel(
      jobId: json['job_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      message: result is Map<String, dynamic>
          ? ChatMessageModel.fromJobResult(result)
          : null,
    );
  }
}
