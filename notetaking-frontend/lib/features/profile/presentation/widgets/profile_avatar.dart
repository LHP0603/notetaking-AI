import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onEditTap;
  final bool showEditButton;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.size = 120,
    this.onEditTap,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8D5B7),
            border: Border.all(
              color: const Color(0xFFD4B896),
              width: 4,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                : _buildDefaultAvatar(),
          ),
        ),
        // Edit button
        if (showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF101822),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFE8D5B7),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.5,
          color: const Color(0xFFD4C4A8),
        ),
      ),
    );
  }
}





