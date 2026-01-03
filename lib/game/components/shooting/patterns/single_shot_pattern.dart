import 'package:flame/components.dart';
import '../bullet_config.dart';
import '../shooting_pattern.dart';

/// Fires a single bullet straight down
class SingleShotPattern extends ShootingPattern {
  final Vector2 offset;
  final double speedMultiplier;

  SingleShotPattern({
    Vector2? offset,
    this.speedMultiplier = 1.0,
  }) : offset = offset ?? Vector2.zero();

  @override
  List<BulletConfig> getBullets(Vector2 origin, {Vector2? targetPosition}) {
    return [
      BulletConfig(
        offset: offset.clone(),
        angle: 0.0,
        speedMultiplier: speedMultiplier,
      ),
    ];
  }
}
