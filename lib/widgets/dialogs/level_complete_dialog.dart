import 'package:flutter/material.dart';
import '../star_rating.dart';

class LevelCompleteDialog extends StatelessWidget {
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
  final bool allEnemiesKilled;
  final bool noDamageTaken;

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
    required this.allEnemiesKilled,
    required this.noDamageTaken,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          // Star rating with animation
          StarRating(
            stars: starsEarned,
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
          // Star requirements breakdown
          _buildStarRequirement(
            icon: Icons.check_circle,
            label: 'Level Complete',
            achieved: true, // Always true in victory dialog
          ),
          _buildStarRequirement(
            icon: Icons.gps_fixed,
            label: 'All Enemies Killed ($kills/$totalEnemies)',
            achieved: allEnemiesKilled,
          ),
          _buildStarRequirement(
            icon: Icons.shield,
            label: 'No Damage Taken',
            achieved: noDamageTaken,
          ),
          SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.timer, '${timeSurvived.toStringAsFixed(1)}s', 'Time'),
              _buildStatItem(Icons.my_location, '$kills', 'Kills'),
              _buildStatItem(Icons.heart_broken, '$damageTaken', 'Damage'),
            ],
          ),
          SizedBox(height: 24),
          if (hasNextLevel)
            _buildButton('Next Level', Colors.green, Icons.arrow_forward, onNextLevel),
          if (hasNextLevel) SizedBox(height: 12),
          _buildButton('Restart', Colors.orange, Icons.refresh, onRestart),
          SizedBox(height: 12),
          _buildButton('Level Select', Colors.blue, Icons.list, onLevelSelect),
        ],
      ),
    );
  }

  Widget _buildStarRequirement({
    required IconData icon,
    required String label,
    required bool achieved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.star : Icons.star_border,
            color: achieved ? Colors.amber : Colors.grey,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: achieved ? Colors.white : Colors.grey[500],
                fontSize: 14,
                decoration: achieved ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Icon(
            achieved ? Icons.check : Icons.close,
            color: achieved ? Colors.green : Colors.red[300],
            size: 18,
          ),
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
