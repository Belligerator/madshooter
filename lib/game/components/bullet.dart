import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';
import 'soldier.dart';

class Bullet extends RectangleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 300.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Small green bullet
    size = Vector2(3, 8);
    paint = Paint()..color = Colors.green;

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

    // Check if bullet collided with a soldier
    if (other is Soldier) {
      // Remove both bullet and soldier
      removeFromParent();
      other.removeFromParent();
      return false; // Stop processing more collisions for this bullet
    }

    return true;
  }
}