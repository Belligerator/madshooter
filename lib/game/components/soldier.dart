import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../shooting_game.dart';

class Soldier extends RectangleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 50.0;
  static final Random _random = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create soldier - smaller than player (20x25 vs player's 30x40)
    size = Vector2(20, 25);
    paint = Paint()..color = Colors.red;

    // Add collision detection
    add(RectangleHitbox());

    // Spawn at random position within road bounds at top of screen
    final roadWidth = 200.0;
    final centerX = gameRef.size.x / 2;
    final leftBound = centerX - roadWidth / 2;
    final rightBound = centerX + roadWidth / 2 - size.x;

    // Random X position within road
    final randomX = leftBound + _random.nextDouble() * (rightBound - leftBound);
    position = Vector2(randomX, -size.y); // Start just above screen
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move soldier downward
    position.y += speed * dt;

    // Remove soldier when it goes off-screen (bottom)
    if (position.y > gameRef.size.y) {
      removeFromParent();
    }
  }
}