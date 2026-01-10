import 'package:flutter/material.dart';

class TranscriptCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final VoidCallback? onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final bool showArrow;

  const TranscriptCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    this.onTap,
    this.icon = Icons.article_outlined,
    this.backgroundColor = const Color(0xFF282E39),
    this.iconBackgroundColor = const Color(0xFF1C2128),
    this.showArrow = true,
  });

  /// Factory constructor to create from a map
  factory TranscriptCard.fromMap(
    Map<String, dynamic> data, {
    VoidCallback? onTap,
  }) {
    return TranscriptCard(
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.grey[500],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$date • $time',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// A variant of TranscriptCard with duration instead of date/time
class TranscriptCardWithDuration extends StatelessWidget {
  final String title;
  final Duration duration;
  final DateTime? createdAt;
  final VoidCallback? onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final bool showArrow;

  const TranscriptCardWithDuration({
    super.key,
    required this.title,
    required this.duration,
    this.createdAt,
    this.onTap,
    this.icon = Icons.article_outlined,
    this.backgroundColor = const Color(0xFF282E39),
    this.iconBackgroundColor = const Color(0xFF1C2128),
    this.showArrow = true,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.grey[500],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (createdAt != null) ...[
                        Text(
                          _formatDate(createdAt!),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            if (showArrow)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}












