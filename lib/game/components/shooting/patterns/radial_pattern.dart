import 'dart:math';
import 'package:flame/components.dart';
import '../bullet_config.dart';
import '../shooting_pattern.dart';

/// Fires bullets in all directions (360 degrees)
class RadialPattern extends ShootingPattern {
  /// Number of bullets around the circle
  final int bulletCount;
  
  /// Starting angle offset in degrees (0 = first bullet fires straight down)
  final double startAngle;
  
  /// Offset from shooter position
  final Vector2 offset;
  
  /// Speed multiplier for all bullets
  final double speedMultiplier;

  RadialPattern({
    this.bulletCount = 8,
    this.startAngle = 0.0,
    Vector2? offset,
    this.speedMultiplier = 1.0,
  }) : offset = offset ?? Vector2.zero();

  @override
  List<BulletConfig> getBullets(Vector2 origin, {Vector2? targetPosition}) {
    final bullets = <BulletConfig>[];
    
    final angleStep = (2 * pi) / bulletCount;
    final startRad = startAngle * pi / 180;

    for (int i = 0; i < bulletCount; i++) {
      final bulletAngle = startRad + (angleStep * i);
      bullets.add(BulletConfig(
        offset: offset.clone(),
        angle: bulletAngle,
        speedMultiplier: speedMultiplier,
      ));
    }

    return bullets;
  }
}
