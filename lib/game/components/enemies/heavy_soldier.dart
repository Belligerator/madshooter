import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'base_enemy.dart';

class HeavySoldier extends BaseEnemy {
  // Original sprite dimensions (from image file)
  static const double _originalWidth = 256.0;
  static const double _originalHeight = 256.0;

  // Base display size (what you work with in game)
  static const double _baseWidth = 100.0;
  static const double _baseHeight = _baseWidth * (_originalHeight / _originalWidth);

  // Scale factor from original to base size
  static double get displayScale => _baseWidth / _originalWidth;

  // Hitbox dimensions (relative to original sprite)
  static const double _hitboxWidth = 122.0;
  static const double _hitboxHeight = 130.0;

  // Scaled hitbox getters (for positioning from other components)
  static double get scaledHitboxWidth => _hitboxWidth * displayScale;
  static double get scaledHitboxHeight => _hitboxHeight * displayScale;

  HeavySoldier({
    super.cachedSprite,
    super.spawnXPercent,
    super.spawnYOffset,
    super.dropUpgradePoints,
    super.destroyedOnPlayerCollision,
    super.movementBehavior,
  }) : super(
    maxHealth: 500,
    spritePath: 'enemies/Enemy_Tank_Base.webp',
    baseWidth: _baseWidth,
    baseHeight: _baseHeight,
    healthBarWidth: scaledHitboxWidth,
    healthBarX: _baseWidth / 2 - scaledHitboxWidth / 2,
    healthBarY: _baseHeight / 2 - scaledHitboxHeight / 2,
  );

  @override
  void addHitboxes() {
    add(
      CircleHitbox(
        radius: scaledHitboxWidth / 2,
        position: Vector2(_baseWidth / 2, _baseHeight / 2),
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ),
    );
  }

  @override
  double getSpeed() => super.getSpeed() * 0.5;
}
