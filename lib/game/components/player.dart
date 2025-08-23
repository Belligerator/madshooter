import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

class Player extends RectangleComponent with HasGameRef<ShootingGame> {
  static const double speed = 100.0;
  late double leftBoundary;
  late double rightBoundary;
  late double centerX;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create simple player rectangle (we'll replace with sprites later)
    size = Vector2(30, 40);
    paint = Paint()..color = Colors.blue;

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
    final targetX = centerX + (joystickX * 2); // 2 pixels max movement from center

    // Clamp to road boundaries
    final clampedX = targetX.clamp(leftBoundary, rightBoundary);
    position.x = clampedX - size.x / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // No need for smooth interpolation anymore - direct response feels better
  }
}