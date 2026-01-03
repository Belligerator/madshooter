import 'package:flame/components.dart';
import '../bullet_config.dart';
import '../shooting_pattern.dart';

/// Fires multiple bullets in rapid succession with delays
class BurstPattern extends ShootingPattern {
  /// Number of bullets in the burst
  final int bulletCount;
  
  /// Delay between each bullet in seconds
  final double delayBetweenShots;
  
  /// Offset from shooter position
  final Vector2 offset;
  
  /// Speed multiplier for all bullets
  final double speedMultiplier;

  BurstPattern({
    this.bulletCount = 3,
    this.delayBetweenShots = 0.1,
    Vector2? offset,
    this.speedMultiplier = 1.0,
  }) : offset = offset ?? Vector2.zero();

  @override
  List<BulletConfig> getBullets(Vector2 origin, {Vector2? targetPosition}) {
    final bullets = <BulletConfig>[];

    for (int i = 0; i < bulletCount; i++) {
      bullets.add(BulletConfig(
        offset: offset.clone(),
        angle: 0.0,
        speedMultiplier: speedMultiplier,
        delay: i * delayBetweenShots,
      ));
    }

    return bullets;
  }
}
