import 'package:flutter/material.dart';
import '../game/shooting_game.dart';

class UpMeter extends StatelessWidget {
  final int currentPoints;
  final int maxPoints;
  final UpgradeTier? currentTier;
  final VoidCallback? onTap;

  const UpMeter({
    super.key,
    required this.currentPoints,
    this.maxPoints = 10,
    this.currentTier,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canUpgrade = currentTier != null;

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canUpgrade ? _getTierColor() : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // UP count display
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text(
                  '$currentPoints',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          // Tier icons
          _buildTierIcon(
            tier: UpgradeTier.bulletSize,
            icon: Icons.circle,
            label: '1',
            requiredUp: 1,
          ),
          SizedBox(height: 4),
          _buildTierIcon(
            tier: UpgradeTier.fireRate,
            icon: Icons.speed,
            label: '2',
            requiredUp: 2,
          ),
          SizedBox(height: 4),
          _buildTierIcon(
            tier: UpgradeTier.ally,
            icon: Icons.person_add,
            label: '3',
            requiredUp: 3,
          ),
          SizedBox(height: 8),

          // Upgrade button
          GestureDetector(
            onTap: canUpgrade ? onTap : null,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: canUpgrade ? _getTierColor() : Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                boxShadow: canUpgrade
                    ? [
                        BoxShadow(
                          color: _getTierColor().withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upgrade,
                    color: canUpgrade ? Colors.white : Colors.grey,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Text(
                    canUpgrade ? 'UP!' : '---',
                    style: TextStyle(
                      color: canUpgrade ? Colors.white : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierIcon({
    required UpgradeTier tier,
    required IconData icon,
    required String label,
    required int requiredUp,
  }) {
    final isActive = currentTier == tier;
    final isAvailable = currentPoints >= requiredUp;
    final color = _getTierColorFor(tier);

    // Fixed size container to prevent layout shifts
    return SizedBox(
      width: 70,
      height: 36,
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(50) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : (isAvailable ? color.withAlpha(100) : Colors.grey[700]!),
            width: 2, // Always same width
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isActive ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? color : (isAvailable ? color.withAlpha(100) : Colors.grey[700]!),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : (isAvailable ? color : Colors.grey),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 6),
            Icon(
              icon,
              color: isActive ? color : (isAvailable ? color.withAlpha(150) : Colors.grey[600]),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor() {
    if (currentTier == null) return Colors.grey;
    return _getTierColorFor(currentTier!);
  }

  Color _getTierColorFor(UpgradeTier tier) {
    switch (tier) {
      case UpgradeTier.bulletSize:
        return Colors.brown[400]!;
      case UpgradeTier.fireRate:
        return Colors.orange;
      case UpgradeTier.ally:
        return Colors.green;
    }
  }
}
