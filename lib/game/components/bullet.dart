import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

class Bullet extends RectangleComponent with HasGameRef<ShootingGame> {
  static const double speed = 300.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Small yellow bullet
    size = Vector2(3, 8);
    paint = Paint()..color = Colors.yellow;
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
}