import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';
import 'bullet.dart';

class Player extends RectangleComponent with HasGameRef<ShootingGame> {
  static const double speed = 200.0;
  static const double fireRate = 0.3; // Seconds between shots

  late double leftBoundary;
  late double rightBoundary;
  late double centerX;

  double _timeSinceLastShot = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create simple player rectangle (we'll replace with sprites later)
    size = Vector2(30, 40);
    paint = Paint()..color = Colors.blue;

    // Set higher priority/z-index to render on top
    priority = 100; // Higher value renders on top

    // Set boundaries for player movement (stay within road)
    final roadWidth = 200.0;
    centerX = gameRef.size.x / 2;
    leftBoundary = centerX - roadWidth / 2 + size.x / 2;
    rightBoundary = centerX + roadWidth / 2 - size.x / 2;

    // Set initial position at bottom center
    position = Vector2(centerX - size.x / 2, gameRef.size.y - 80);
  }

  void move(double joystickX) {
    // Direct proportional movement based on joystick input
    // joystickX ranges from -1.0 to 1.0
    final targetX = centerX + (joystickX * 2); // Modified value from user

    // Clamp to road boundaries
    final clampedX = targetX.clamp(leftBoundary, rightBoundary);
    position.x = clampedX - size.x / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle automatic shooting
    _timeSinceLastShot += dt;

    if (_timeSinceLastShot >= fireRate) {
      _shoot();
      _timeSinceLastShot = 0;
    }
  }

  void _shoot() {
    // Create bullet at player's position
    final bullet = Bullet();
    bullet.position = Vector2(
      position.x + size.x / 2 - bullet.size.x / 2, // Center bullet on player
      position.y - bullet.size.y, // Spawn just above player
    );

    // Add bullet to the game
    gameRef.add(bullet);
  }
}