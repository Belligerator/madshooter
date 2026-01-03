import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dart:math';
import '../shooting_game.dart';
import 'player.dart';

class EnemyBullet extends SpriteAnimationComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double baseSpeed = 200.0;

  // Original sprite dimensions (from image file)
  static const double _originalWidth = 343.0;
  static const double _originalHeight = 274.0;

  // Base display size (scaled down for game)
  static const double baseWidth = 60.0; // Slightly smaller than player bullets
  static const double baseHeight = baseWidth * (_originalHeight / _originalWidth);

  // Hitbox dimensions (relative to original sprite)
  static const double hitboxWidth = 13.0;
  static const double hitboxHeight = 38.0;
  static const double hitboxOffsetY = 26.0;

  // Scale factor from original to base size
  static double get displayScale => baseWidth / _originalWidth;

  final Vector2 origin;
  
  /// Direction angle in radians (0 = down, positive = clockwise)
  final double directionAngle;
  
  /// Speed multiplier (1.0 = baseSpeed)
  final double speedMultiplier;
  
  final double angleCorrection = pi; // Rotate 180 degrees

  EnemyBullet({
    required this.origin,
    this.directionAngle = 0.0,
    this.speedMultiplier = 1.0,
  });

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the bullet sprites (reusing player bullet sprites for now)
    final sprites = await Future.wait([
      game.loadSprite('bullet/Projectile_Player_Bullet1.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet2.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet3.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet4.webp'),
      game.loadSprite('bullet/Projectile_Player_Bullet5.webp'),
    ]);

    // Create animation
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.1, loop: true);

    size = Vector2(baseWidth, baseHeight);
    anchor = Anchor.center;
    
    // Rotate sprite to face movement direction
    // angleCorrection (π) flips sprite to face down, then subtract directionAngle
    // because positive directionAngle moves right but rotates clockwise
    angle = angleCorrection - directionAngle;

    position = origin;

    // Add collision detection
    final scaledHitboxWidth = hitboxWidth * displayScale;
    add(
      RectangleHitbox(
        size: Vector2(scaledHitboxWidth, hitboxHeight * displayScale * 3),
        position: Vector2((baseWidth - scaledHitboxWidth) / 2, hitboxOffsetY * displayScale),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Calculate velocity based on direction angle
    // 0 = down (+Y), positive angles rotate clockwise
    final speed = baseSpeed * speedMultiplier;
    final vx = sin(directionAngle) * speed;
    final vy = cos(directionAngle) * speed;
    
    position.x += vx * dt;
    position.y += vy * dt;

    // Remove bullet when it goes off-screen (any direction)
    if (position.y > game.gameHeight + size.y ||
        position.y < -size.y ||
        position.x < -size.x ||
        position.x > game.gameWidth + size.x) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Player) {
      // Damage the player
      game.takeDamage(1);
      removeFromParent();
    }
  }
}
