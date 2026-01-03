import 'dart:math';
import 'package:flame/components.dart';
import '../bullet_config.dart';
import '../shooting_pattern.dart';

/// Fires a bullet aimed at the target position (e.g., player)
class AimedPattern extends ShootingPattern {
  /// Offset from shooter position
  final Vector2 offset;
  
  /// Speed multiplier for the bullet
  final double speedMultiplier;
  
  /// Accuracy variance in degrees (0 = perfect aim, 10 = ±10 degree spread)
  final double accuracy;

  final Random _random = Random();

  AimedPattern({
    Vector2? offset,
    this.speedMultiplier = 1.0,
    this.accuracy = 0.0,
  }) : offset = offset ?? Vector2.zero();

  @override
  List<BulletConfig> getBullets(Vector2 origin, {Vector2? targetPosition}) {
    double angle = 0.0; // Default: straight down
    
    if (targetPosition != null) {
      // Calculate angle to target
      // Note: In game coordinates, +Y is down, so angle 0 = down
      final dx = targetPosition.x - origin.x;
      final dy = targetPosition.y - origin.y;
      angle = atan2(dx, dy); // atan2(x, y) because we want 0 = down (+y direction)
    }
    
    // Apply accuracy variance
    if (accuracy > 0) {
      final variance = (accuracy * pi / 180) * (2 * _random.nextDouble() - 1);
      angle += variance;
    }

    return [
      BulletConfig(
        offset: offset.clone(),
        angle: angle,
        speedMultiplier: speedMultiplier,
      ),
    ];
  }
}
