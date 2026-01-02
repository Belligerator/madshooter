import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../shooting_game.dart';
import 'enemies/base_enemy.dart';
import 'barrel.dart';

class Bullet extends SpriteAnimationComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double speed = 300.0;

  // Original sprite dimensions (from image file)
  static const double _originalWidth = 343.0;
  static const double _originalHeight = 274.0;

  // Base display size (scaled down for game)
  static const double baseWidth = 80.0;
  static const double baseHeight = baseWidth * (_originalHeight / _originalWidth);

  // Hitbox dimensions (relative to original sprite)
  static const double hitboxWidth = 13.0;
  static const double hitboxHeight = 38.0;
  static const double hitboxOffsetY = 26.0;  // Y offset from top

  // Scale factor from original to base size
  static double get displayScale => baseWidth / _originalWidth;

  // Scaled hitbox getters (for positioning from other components)
  static double get scaledHitboxWidth => hitboxWidth * displayScale;
  static double get scaledHitboxHeight => hitboxHeight * displayScale;
  static double get scaledHitboxOffsetY => hitboxOffsetY * displayScale;
  static Vector2 get scaledHitboxSize => Vector2(scaledHitboxWidth, scaledHitboxHeight);

  final Vector2 origin;

  Vector2 get baseSize => Vector2(baseWidth, baseHeight);

  Bullet({required this.origin});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // debugMode = true;

    // Load the 5 bullet sprites
    final sprites = await Future.wait([
      game.loadSprite('bullet/Projectile_Player_Bullet1.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet2.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet3.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet4.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet5.webp'),
    ]);

    // Create animation (plays once and stops on last frame)
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.1, loop: true);

    // Get bullet size from game (with upgrades applied)
    size = baseSize;
    anchor = Anchor.topCenter;
    scale = Vector2.all(game.bulletSizeMultiplier);

    // Position bullet at origin (anchor handles centering)
    position = Vector2(
      origin.x, // Center X (topCenter anchor)
      origin.y, // Top of bullet at origin Y
    );

    // Add collision detection (centered horizontally)
    final scaledHitboxWidth = hitboxWidth * displayScale;
    add(
      CircleHitbox(
        radius: scaledHitboxWidth / 2,
        position: Vector2(baseWidth / 2, hitboxOffsetY * displayScale + scaledHitboxWidth / 2),
        anchor: Anchor.center
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move bullet upward
    position.y -= speed * dt;

    // Remove bullet when it goes off-screen
    if (position.y < -size.y) {
      removeFromParent();
    }
  }

  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // Check if bullet collided with any enemy
    if (other is BaseEnemy) {
      // Damage the enemy
      other.takeDamage(game.getBulletDamage());

      // Remove bullet
      removeFromParent();
      return false; // Stop processing more collisions for this bullet
    }

    // Check if bullet collided with a barrel
    if (other is Barrel) {
      // Damage the barrel
      other.takeDamage(game.getBulletDamage());

      // Remove the bullet
      removeFromParent();
      return false; // Stop processing more collisions for this bullet
    }

    return true;
  }
}
