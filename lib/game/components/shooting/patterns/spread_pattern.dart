import 'dart:math';
import 'package:flame/components.dart';
import '../bullet_config.dart';
import '../shooting_pattern.dart';

/// Fires multiple bullets in a spread/fan pattern
class SpreadPattern extends ShootingPattern {
  /// Number of bullets in the spread
  final int bulletCount;
  
  /// Total angle of the spread in degrees (e.g., 45 means ±22.5 degrees)
  final double spreadAngle;
  
  /// Offset from shooter position
  final Vector2 offset;
  
  /// Speed multiplier for all bullets
  final double speedMultiplier;

  SpreadPattern({
    this.bulletCount = 3,
    this.spreadAngle = 30.0,
    Vector2? offset,
    this.speedMultiplier = 1.0,
  }) : offset = offset ?? Vector2.zero();

  @override
  List<BulletConfig> getBullets(Vector2 origin, {Vector2? targetPosition}) {
    final bullets = <BulletConfig>[];
    
    if (bulletCount == 1) {
      bullets.add(BulletConfig(
        offset: offset.clone(),
        angle: 0.0,
        speedMultiplier: speedMultiplier,
      ));
      return bullets;
    }

    // Convert spread angle to radians
    final spreadRad = spreadAngle * pi / 180;
    final halfSpread = spreadRad / 2;
    final angleStep = spreadRad / (bulletCount - 1);

    for (int i = 0; i < bulletCount; i++) {
      final bulletAngle = -halfSpread + (angleStep * i);
      bullets.add(BulletConfig(
        offset: offset.clone(),
        angle: bulletAngle,
        speedMultiplier: speedMultiplier,
      ));
    }

    return bullets;
  }
}
