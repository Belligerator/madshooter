import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int stars;
  final int maxStars;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final bool showAnimation;

  const StarRating({
    super.key,
    required this.stars,
    this.maxStars = 3,
    this.size = 24.0,
    this.filledColor = Colors.amber,
    this.emptyColor = Colors.grey,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final isFilled = index < stars;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: showAnimation && isFilled
              ? _AnimatedStar(
                  size: size,
                  color: filledColor,
                  delay: Duration(milliseconds: 200 * index),
                )
              : Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  size: size,
                  color: isFilled ? filledColor : emptyColor,
                ),
        );
      }),
    );
  }
}

class _AnimatedStar extends StatefulWidget {
  final double size;
  final Color color;
  final Duration delay;

  const _AnimatedStar({
    required this.size,
    required this.color,
    required this.delay,
  });

  @override
  State<_AnimatedStar> createState() => _AnimatedStarState();
}

class _AnimatedStarState extends State<_AnimatedStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Icon(
        Icons.star,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
