import 'package:flutter/material.dart';

class SubscriptionBadge extends StatelessWidget {
  final String label;
  final bool isPremium;

  const SubscriptionBadge({
    super.key,
    required this.label,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPremium 
            ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
            : Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
        border: isPremium
            ? Border.all(color: const Color(0xFF3B82F6), width: 1)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[
            const Icon(
              Icons.star,
              color: Color(0xFF3B82F6),
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: isPremium ? const Color(0xFF3B82F6) : Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}












