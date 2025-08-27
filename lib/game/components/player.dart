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
    centerX = gameRef.size.x / 2;
    leftBoundary = centerX - gameRef.roadWidth / 2 + size.x / 2; // Use gameRef.roadWidth
    rightBoundary = centerX + gameRef.roadWidth / 2 - size.x / 2; // Use gameRef.roadWidth

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

    // Handle automatic shooting with upgraded fire rate
    _timeSinceLastShot += dt;

    final currentFireRate = gameRef.getFireRate(); // Get upgraded fire rate

    if (_timeSinceLastShot >= currentFireRate) {
      _shoot();
      _timeSinceLastShot = 0;
    }
  }

  void _shoot() {
    // Calculate the origin point (center of player at top)
    final originPoint = Vector2(
      position.x + size.x / 2, // Center X of player
      position.y,              // Top Y of player
    );

    // Create bullet with origin point - bullet will handle its own positioning
    final bullet = Bullet(origin: originPoint);

    // Add bullet to the game
    gameRef.add(bullet);
  }
}