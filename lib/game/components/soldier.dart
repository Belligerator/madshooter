import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';

class Soldier extends CircleComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double speed = 120.0; // Soldier movement speed, a little faster than road scroll
  static final Random _random = Random();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create circular soldier - radius of 12 (diameter ~24, similar to previous 20x25 rectangle)
    radius = 12.0;
    paint = Paint()..color = Colors.red;

    // Set lower priority/z-index to render behind player
    priority = 50; // Lower value renders behind

    // Add collision detection for circle
    add(CircleHitbox());

    // Spawn at random position within road bounds at top of game area (below header)
    final roadWidth = 200.0;
    final centerX = game.gameWidth / 2;
    final leftBound = centerX - roadWidth / 2 + radius * 2; // Account for radius
    final rightBound = centerX + roadWidth / 2 - radius * 2; // Account for radius

    // Random X position within road
    final randomX = leftBound + _random.nextDouble() * (rightBound - leftBound);
    position = Vector2(randomX, -radius * 2); // Start just above screen, account for radius
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move soldier downward
    position.y += speed * dt;

    // Remove soldier when it goes off-screen (bottom)
    if (position.y > game.gameHeight + radius) { // Account for radius
      removeFromParent();
    }
  }
}