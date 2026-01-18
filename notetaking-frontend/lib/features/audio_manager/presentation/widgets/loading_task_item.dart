import 'package:flutter/material.dart';
import 'common_task_item.dart';

class LoadingTaskItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const LoadingTaskItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CommonTaskItem(
      icon: icon,
      iconColor: iconColor,
      title: title,
      description: description,
      onTap: onTap,
      isLoading: true,
      showChevron: false,
    );
  }
}
