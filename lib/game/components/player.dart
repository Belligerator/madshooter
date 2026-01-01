import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';
import 'bullet.dart';
import 'upgrade_point.dart';
import 'enemies/base_enemy.dart';

class Player extends CircleComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double speed = 200.0;
  static const double playerRadius = 12.0;
  static const double playerBottomPositionY = 100.0;

  late double leftBoundary = 0;
  late double rightBoundary = game.gameWidth - 2 * playerRadius;
  late double topBoundary = 0;
  late double bottomBoundary = game.gameHeight - 2 * playerRadius;

  double _timeSinceLastShot = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create circular player (same pattern as soldiers)
    radius = playerRadius;
    paint = Paint()..color = Colors.blue;

    // Set priority to render above enemies but below header
    priority = 100;

    // Add collision detection
    add(CircleHitbox());

    // Position at bottom center of game world
    final centerX = game.gameWidth / 2 - radius;
    position = Vector2(centerX, game.gameHeight - playerBottomPositionY - radius);
  }

  void move(double joystickX, double joystickY) {
    // Direct proportional movement based on joystick input
    position.x += joystickX * 2;
    position.y += joystickY * 2;

    // Clamp to screen boundaries
    position.x = position.x.clamp(leftBoundary, rightBoundary);
    position.y = position.y.clamp(topBoundary, bottomBoundary);
  }

  void moveToSliderPosition(double sliderValue) {
    // Convert slider value (0.0 to 1.0) to player position
    // 0.0 = left boundary, 1.0 = right boundary
    final targetX = leftBoundary + (rightBoundary - leftBoundary) * sliderValue;
    position.x = targetX;
  }

  void moveByDelta(double deltaX, double deltaY) {
    // Move player by the same amount as thumb (1:1 relative movement)
    position.x += deltaX;
    position.y += deltaY;
    position.x = position.x.clamp(leftBoundary, rightBoundary);
    position.y = position.y.clamp(topBoundary, bottomBoundary);
  }

  // Joystick-style constant speed movement
  static const double baseSpeed = 200.0; // pixels per second
  double speedMultiplier = 1.0; // can be upgraded later

  void moveConstantSpeed(int direction, double dt) {
    final moveSpeed = baseSpeed * speedMultiplier;
    position.x += direction * moveSpeed * dt;

    // Clamp to road boundaries
    position.x = position.x.clamp(leftBoundary, rightBoundary);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle automatic shooting with upgraded fire rate
    _timeSinceLastShot += dt;

    final currentFireInterval = game.getFireInterval(); // Get seconds between shots

    if (_timeSinceLastShot >= currentFireInterval) {
      _shoot();
      _timeSinceLastShot = 0;
    }
  }

  void _shoot() {
    // Calculate the origin point (center of player at top)
    final originPoint = Vector2(
      position.x + radius, // Center X of player (CircleComponent position is center)
      position.y - radius, // Top of player circle
    );

    // Create bullet with origin point
    final bullet = Bullet(origin: originPoint);

    // Add bullet to the game world
    game.world.add(bullet);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is UpgradePoint) {
      other.collect();
    }

    // Handle enemy collision
    if (other is BaseEnemy) {
      other.onPlayerCollision();
    }
  }
}
