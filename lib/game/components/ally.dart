import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';
import 'bullet.dart';

class Ally extends CircleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  final Vector2 offsetFromPlayer; // Position relative to main player
  double _timeSinceLastShot = 0;

  Ally({required this.offsetFromPlayer});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create ally (slightly smaller and different color than main player)
    radius = 10.0; // Slightly smaller than main player (12.0)
    paint = Paint()..color = Colors.lightBlue; // Light blue to distinguish from main player

    // Set priority to render above enemies but below main player
    priority = 90;

    // Add collision detection
    add(CircleHitbox());
  }

  void updatePosition(Vector2 playerPosition) {
    // Position ally relative to main player
    position = playerPosition + offsetFromPlayer;

    // Keep ally within road boundaries
    final centerX = gameRef.size.x / 2 - radius;
    final leftBoundary = centerX - gameRef.roadWidth / 2 - radius * 2;
    final rightBoundary = centerX + gameRef.roadWidth / 2 + radius * 2;

    position.x = position.x.clamp(leftBoundary, rightBoundary);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle automatic shooting (same fire rate as main player)
    _timeSinceLastShot += dt;

    final currentFireInterval = gameRef.getFireInterval();

    if (_timeSinceLastShot >= currentFireInterval) {
      _shoot();
      _timeSinceLastShot = 0;
    }
  }

  void _shoot() {
    // Calculate the origin point (center of ally at top)
    final originPoint = Vector2(
      position.x + radius, // Center X of ally
      position.y - radius, // Top of ally circle
    );

    // Create bullet with origin point
    final bullet = Bullet(origin: originPoint);

    // Add bullet to the game
    gameRef.add(bullet);
  }
}