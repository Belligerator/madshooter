import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 3: Follows the player's X position while descending.
class TrackPlayerBehavior extends MovementBehavior {
  /// How quickly the enemy reacts to player movement (0-1)
  /// 0 = no tracking, 1 = instant tracking
  final double reactionSpeed;

  /// Maximum horizontal speed multiplier
  final double maxHorizontalSpeedMultiplier;

  TrackPlayerBehavior({
    this.reactionSpeed = 0.5,
    this.maxHorizontalSpeedMultiplier = 2.0,
  });

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    double horizontalVelocity = 0;

    // Guard against zero/tiny dt
    if (dt <= 0.0001) {
      return Vector2(0, baseSpeed);
    }

    // Get player position if available
    if (getPlayerPosition != null) {
      final playerPos = getPlayerPosition!();
      final targetX = playerPos.x;

      // Calculate difference to player
      final dx = targetX - currentPosition.x;

      // Apply reaction speed (lerp towards player)
      horizontalVelocity = dx * reactionSpeed * 5; // Scale for responsiveness

      // Clamp to max speed
      final maxSpeed = baseSpeed * maxHorizontalSpeedMultiplier;
      horizontalVelocity = horizontalVelocity.clamp(-maxSpeed, maxSpeed);

      // Clamp to road bounds
      final nextX = currentPosition.x + horizontalVelocity * dt;
      if (nextX < roadLeftBound) {
        horizontalVelocity = (roadLeftBound - currentPosition.x) / dt;
      } else if (nextX > roadRightBound) {
        horizontalVelocity = (roadRightBound - currentPosition.x) / dt;
      }
    }

    return Vector2(horizontalVelocity, baseSpeed);
  }
}
