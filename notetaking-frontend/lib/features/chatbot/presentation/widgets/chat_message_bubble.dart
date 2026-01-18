import 'package:flutter/material.dart';
import '../../domain/entities/audio_reference.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/note_reference.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final double maxWidth;
  final ValueChanged<AudioReference>? onAudioTap;
  final ValueChanged<NoteReference>? onNoteTap;
  final ValueChanged<String>? onSuggestedQuestionTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.maxWidth,
    this.onAudioTap,
    this.onNoteTap,
    this.onSuggestedQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubbleColor = isUser ? const Color(0xFF3B82F6) : Colors.grey[200];
    final textColor = isUser ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(color: textColor),
            ),
          ),
        ),
        if (message.audioReferences?.isNotEmpty ?? false)
          _buildAudioReferences(context),
        if (message.noteReferences?.isNotEmpty ?? false)
          _buildNoteReferences(context),
        if (message.suggestedQuestions?.isNotEmpty ?? false)
          _buildSuggestedQuestions(context),
      ],
    );
  }

  Widget _buildAudioReferences(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...message.audioReferences!.map(
          (audio) => _buildAudioCard(context, audio),
        ),
      ],
    );
  }

  Widget _buildAudioCard(BuildContext context, AudioReference audio) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onAudioTap == null ? null : () => onAudioTap!(audio),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.audio_file,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audio.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      audio.formattedDuration,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteReferences(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...message.noteReferences!.map(
          (note) => _buildNoteCard(context, note),
        ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteReference note) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onNoteTap == null ? null : () => onNoteTap!(note),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.note,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedQuestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Suggested questions:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: message.suggestedQuestions!.map((question) {
            return ActionChip(
              label: Text(
                question,
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: onSuggestedQuestionTap == null
                  ? null
                  : () => onSuggestedQuestionTap!(question),
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            );
          }).toList(),
        ),
      ],
    );
  }
}
