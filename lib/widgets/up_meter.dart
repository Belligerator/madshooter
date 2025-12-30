import 'package:flutter/material.dart';
import '../game/shooting_game.dart';

class UpMeter extends StatelessWidget {
  final int upgradePoints;
  final int bulletSizeLevel;
  final int fireRateLevel;
  final int allyLevel;
  final void Function(UpgradeTier tier)? onUpgradeTap;

  const UpMeter({
    super.key,
    required this.upgradePoints,
    required this.bulletSizeLevel,
    required this.fireRateLevel,
    required this.allyLevel,
    this.onUpgradeTap,
  });

  bool _isTierAvailable(UpgradeTier tier) {
    switch (tier) {
      case UpgradeTier.bulletSize:
        return upgradePoints >= 1;
      case UpgradeTier.fireRate:
        return upgradePoints >= 2;
      case UpgradeTier.ally:
        return upgradePoints >= 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildUpgradeItem(
            tier: UpgradeTier.bulletSize,
            icon: Icons.circle,
            level: bulletSizeLevel,
          ),
          SizedBox(width: 4),
          _buildUpgradeItem(
            tier: UpgradeTier.fireRate,
            icon: Icons.speed,
            level: fireRateLevel,
          ),
          SizedBox(width: 4),
          _buildUpgradeItem(
            tier: UpgradeTier.ally,
            icon: Icons.person,
            level: allyLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeItem({
    required UpgradeTier tier,
    required IconData icon,
    required int level,
  }) {
    final isAvailable = _isTierAvailable(tier);
    final color = Colors.amber;

    return GestureDetector(
      onTap: isAvailable ? () => onUpgradeTap?.call(tier) : null,
      child: Container(
        padding: EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isAvailable ? color.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isAvailable ? color : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isAvailable ? color : Colors.grey[500],
              size: 14,
            ),
            SizedBox(height: 2),
            Text(
              '$level',
              style: TextStyle(
                color: isAvailable ? color : Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate upgrade button widget
class UpgradeButton extends StatelessWidget {
  final bool canUpgrade;
  final VoidCallback? onTap;

  const UpgradeButton({
    super.key,
    required this.canUpgrade,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!canUpgrade) return SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(80),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upgrade,
              color: Colors.black,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'UP!',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
