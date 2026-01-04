import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:madshooter/game/components/enemies/sprites.dart';
import 'base_enemy.dart';

/// Medium-tier enemy that can spawn minions via abilities
class SummonerEnemy extends BaseEnemy {
  // Original sprite dimensions (from image file)
  static const double _originalWidth = 256.0;
  static const double _originalHeight = 256.0;

  // Base display size (what you work with in game)
  static const double _baseWidth = 80.0; // Between basic (60) and heavy (100)
  static const double _baseHeight = _baseWidth * (_originalHeight / _originalWidth);

  // Scale factor from original to base size
  static double get displayScale => _baseWidth / _originalWidth;

  // Hitbox dimensions (relative to original sprite)
  static const double _hitboxWidth = 106.0;
  static const double _hitboxHeight = 106.0;

  // Scaled hitbox getters (for positioning from other components)
  static double get scaledHitboxWidth => _hitboxWidth * displayScale;
  static double get scaledHitboxHeight => _hitboxHeight * displayScale;

  SummonerEnemy({
    super.cachedSprite,
    super.spawnXPercent,
    super.spawnYOffset,
    super.dropUpgradePoints,
    super.destroyedOnPlayerCollision,
    super.movementBehavior,
    super.groupId,
    super.abilities = const [],
  }) : super(
         maxHealth: 300, // Between basic (150) and heavy (500)
         spritePath: EnemySprites.summonerEnemy, // Using tank sprite
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
  double getSpeed() => super.getSpeed() * 0.7; // Slower than basic, faster than heavy
}
