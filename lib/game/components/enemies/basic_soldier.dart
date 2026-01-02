import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'base_enemy.dart';

class BasicSoldier extends BaseEnemy {
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

  BasicSoldier({
    super.spawnXPercent,
    super.spawnYOffset,
    super.dropUpgradePoints,
    super.destroyedOnPlayerCollision,
    super.movementBehavior,
  }) : super(
         maxHealth: 150,
         spritePath: 'enemies/EnemyShip1_Base.webp',
         baseWidth: _baseWidth,
         baseHeight: _baseHeight,
         healthBarWidth: scaledHitboxWidth,
         healthBarX: _baseWidth / 2 - scaledHitboxWidth / 2,
         healthBarY: _baseHeight / 2 - scaledHitboxHeight / 2,
       );

  @override
  void addHitboxes() {
    add(
      RectangleHitbox(
        size: Vector2(scaledHitboxWidth, scaledHitboxHeight),
        position: Vector2(_baseWidth / 2, _baseHeight / 2 - scaledHitboxHeight / 2),
        anchor: Anchor.topCenter,
      ),
    );
  }
}
