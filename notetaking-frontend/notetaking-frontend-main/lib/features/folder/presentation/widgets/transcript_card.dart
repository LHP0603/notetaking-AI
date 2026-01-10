import 'package:flutter/material.dart';

class TranscriptCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const TranscriptCard({
    super.key,
    required this.title,
    required this.date,
    this.isPinned = false,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282E39),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Document icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Title and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            // Pushpin icon
            if (isPinned)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.push_pin, color: Colors.white, size: 20),
              ),
            // More options button
            if (onMoreTap != null)
              GestureDetector(
                onTap: onMoreTap,
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;

    // Format time
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$month $day, $year • $displayHour:$displayMinute $period';
  }
}
