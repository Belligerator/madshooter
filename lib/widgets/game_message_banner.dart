import 'package:flutter/material.dart';

class GameMessageBanner extends StatefulWidget {
  final String message;
  final Duration displayDuration;
  final VoidCallback? onDismissed;

  const GameMessageBanner({
    super.key,
    required this.message,
    this.displayDuration = const Duration(seconds: 3),
    this.onDismissed,
  });

  @override
  State<GameMessageBanner> createState() => _GameMessageBannerState();
}

class _GameMessageBannerState extends State<GameMessageBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start animation
    _controller.forward();

    // Schedule dismiss
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.0),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
                Shadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
