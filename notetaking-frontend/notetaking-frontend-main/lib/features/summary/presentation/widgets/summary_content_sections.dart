import 'package:flutter/material.dart';
import '../../domain/entities/action_item.dart';

class OverviewSection extends StatelessWidget {
  final String overview;

  const OverviewSection({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Text(
      overview,
      style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.6),
    );
  }
}

class KeyPointsSection extends StatelessWidget {
  final List<String> keyPoints;

  const KeyPointsSection({super.key, required this.keyPoints});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          keyPoints.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[500],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class ActionItemsSection extends StatelessWidget {
  final List<ActionItem> actionItems;

  const ActionItemsSection({super.key, required this.actionItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          actionItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[500],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
