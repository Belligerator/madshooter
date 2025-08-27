import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';
import 'bullet.dart';

class Player extends CircleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 200.0;

  late double leftBoundary;
  late double rightBoundary;
  late double centerX;

  double _timeSinceLastShot = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create circular player (same pattern as soldiers)
    radius = 12.0;
    paint = Paint()..color = Colors.blue;

    // Set priority to render above enemies but below header
    priority = 100;

    // Add collision detection
    add(CircleHitbox());

    // Set boundaries and position
    centerX = gameRef.size.x / 2 - radius;
    leftBoundary = centerX - gameRef.roadWidth / 2 - radius * 2;
    rightBoundary = centerX + gameRef.roadWidth / 2 + radius * 2;

    // Position at bottom center of road
    position = Vector2(centerX, gameRef.size.y - 50);
  }

  void move(double joystickX) {
    // Direct proportional movement based on joystick input
    final targetX = centerX + (joystickX * 2);

    // Clamp to road boundaries
    final clampedX = targetX.clamp(leftBoundary, rightBoundary);
    position.x = clampedX;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle automatic shooting with upgraded fire rate
    _timeSinceLastShot += dt;

    final currentFireInterval = gameRef.getFireInterval(); // Get seconds between shots

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

    // Add bullet to the game
    gameRef.add(bullet);
  }
}