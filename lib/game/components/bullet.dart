import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';
import 'enemies/base_enemy.dart';
import 'barrel.dart';

class Bullet extends RectangleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 300.0;
  final Vector2 origin;

  Bullet({required this.origin});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Get bullet size from game (with upgrades applied)
    final bulletSize = gameRef.getBulletSize();
    size = Vector2(bulletSize.x, bulletSize.y);
    paint = Paint()..color = Colors.yellow;

    // Position bullet centered on the origin point
    position = Vector2(
      origin.x - size.x / 2, // Center horizontally on origin
      origin.y - size.y,     // Position just above origin
    );

    // Add collision detection
    add(RectangleHitbox());
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
      other.takeDamage(gameRef.getBulletDamage());

      // Remove bullet
      removeFromParent();
      return false; // Stop processing more collisions for this bullet
    }

    // Check if bullet collided with a barrel
    if (other is Barrel) {
      // Damage the barrel
      other.takeDamage(gameRef.getBulletDamage());

      // Remove the bullet
      removeFromParent();
      return false; // Stop processing more collisions for this bullet
    }

    return true;
  }
}