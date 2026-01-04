import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:madshooter/game/components/enemies/sprites.dart';
import 'base_enemy.dart';

class BasicEnemy extends BaseEnemy {
  // Original sprite dimensions (from image file)
  static const double _originalWidth = 256.0;
  static const double _originalHeight = 256.0;

  // Base display size (what you work with in game)
  static const double _baseWidth = 60.0;
  static const double _baseHeight = _baseWidth * (_originalHeight / _originalWidth);

  // Scale factor from original to base size
  static double get displayScale => _baseWidth / _originalWidth;

  // Hitbox dimensions (relative to original sprite)
  static const double _hitboxWidth = 102.0;
  static const double _hitboxHeight = 110.0;

  // Scaled hitbox getters (for positioning from other components)
  static double get scaledHitboxWidth => _hitboxWidth * displayScale;
  static double get scaledHitboxHeight => _hitboxHeight * displayScale;

  BasicEnemy({
    super.cachedSprite,
    super.spawnXPercent,
    super.spawnYOffset,
    super.dropUpgradePoints,
    super.destroyedOnPlayerCollision,
    super.movementBehavior,
  }) : super(
         maxHealth: 150,
         spritePath: EnemySprites.basicEnemy,
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
}
