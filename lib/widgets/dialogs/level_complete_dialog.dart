import 'package:flutter/material.dart';
import '../star_rating.dart';

class LevelCompleteDialog extends StatefulWidget {
  final double timeSurvived;
  final int kills;
  final int damageTaken;
  final bool hasNextLevel;
  final VoidCallback onNextLevel;
  final VoidCallback onRestart;
  final VoidCallback onLevelSelect;

  // Star rating data
  final int starsEarned;
  final int totalEnemies;
  final double killPercentage;

  const LevelCompleteDialog({
    super.key,
    required this.timeSurvived,
    required this.kills,
    required this.damageTaken,
    required this.hasNextLevel,
    required this.onNextLevel,
    required this.onRestart,
    required this.onLevelSelect,
    required this.starsEarned,
    required this.totalEnemies,
    required this.killPercentage,
  });

  @override
  State<LevelCompleteDialog> createState() => _LevelCompleteDialogState();
}

class _LevelCompleteDialogState extends State<LevelCompleteDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          // Star rating with animation
          StarRating(
            stars: widget.starsEarned,
            size: 40,
            showAnimation: true,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text(
                'Victory!',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star requirements breakdown with animation
          _AnimatedStarRequirement(
            icon: Icons.check_circle,
            label: 'Level Complete',
            achieved: true,
            delay: Duration(milliseconds: 0),
          ),
          _AnimatedStarRequirement(
            icon: Icons.gps_fixed,
            label: '50%+ Kills (${widget.killPercentage.toStringAsFixed(0)}%)',
            achieved: widget.killPercentage >= 50,
            delay: Duration(milliseconds: 400),
          ),
          _AnimatedStarRequirement(
            icon: Icons.military_tech,
            label: '90%+ Kills (${widget.killPercentage.toStringAsFixed(0)}%)',
            achieved: widget.killPercentage >= 90,
            delay: Duration(milliseconds: 800),
          ),
          SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.timer, '${widget.timeSurvived.toStringAsFixed(1)}s', 'Time'),
              _buildStatItem(Icons.my_location, '${widget.kills}/${widget.totalEnemies}', 'Kills'),
            ],
          ),
          SizedBox(height: 24),
          if (widget.hasNextLevel)
            _buildButton('Next Level', Colors.green, Icons.arrow_forward, widget.onNextLevel),
          if (widget.hasNextLevel) SizedBox(height: 12),
          _buildButton('Restart', Colors.orange, Icons.refresh, widget.onRestart),
          SizedBox(height: 12),
          _buildButton('Level Select', Colors.blue, Icons.list, widget.onLevelSelect),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text, style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _AnimatedStarRequirement extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool achieved;
  final Duration delay;

  const _AnimatedStarRequirement({
    required this.icon,
    required this.label,
    required this.achieved,
    required this.delay,
  });

  @override
  State<_AnimatedStarRequirement> createState() => _AnimatedStarRequirementState();
}

class _AnimatedStarRequirementState extends State<_AnimatedStarRequirement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Row(
          children: [
            Icon(
              widget.achieved ? Icons.star : Icons.star_border,
              color: widget.achieved ? Colors.amber : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.achieved ? Colors.white : Colors.grey[500],
                  fontSize: 14,
                  decoration: widget.achieved ? null : TextDecoration.lineThrough,
                ),
              ),
            ),
            Icon(
              widget.achieved ? Icons.check : Icons.close,
              color: widget.achieved ? Colors.green : Colors.red[300],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
