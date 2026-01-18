import 'package:flutter/material.dart';

class AnimatedChatFab extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedChatFab({super.key, required this.onPressed});

  @override
  State<AnimatedChatFab> createState() => _AnimatedChatFabState();
}

class _AnimatedChatFabState extends State<AnimatedChatFab>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _bounceController.forward();
    await _bounceController.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ScaleTransition(
        scale: _bounceAnimation,
        child: FloatingActionButton.extended(
          onPressed: _handleTap,
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('AI Assistant'),
          backgroundColor: const Color(0xFF3B82F6),
          heroTag: 'chatbot_fab',
        ),
      ),
    );
  }
}
