import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../shooting_game.dart';
import '../upgrade_point.dart';

abstract class BaseEnemy extends CircleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double baseSpeed = 50.0;
  static final Random _random = Random();

  int maxHealth;
  int currentHealth;
  Color enemyColor;
  double enemyRadius;
  double? spawnXPercent; // Optional: 0.0-1.0 percentage of road width
  int dropUpgradePoints; // Number of UP to drop when destroyed
  bool destroyedOnPlayerCollision; // Can enemy be destroyed on collision (false for bosses)

  RectangleComponent? healthBarBackground;
  RectangleComponent? healthBarForeground;

  BaseEnemy({
    required this.maxHealth,
    required this.enemyColor,
    required this.enemyRadius,
    this.spawnXPercent,
    this.dropUpgradePoints = 0,
    this.destroyedOnPlayerCollision = true,
  }) : currentHealth = maxHealth;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set size and color
    radius = enemyRadius;
    paint = Paint()..color = enemyColor;

    // Set priority to render above road but below player
    priority = 50;

    // Add collision detection
    add(CircleHitbox());

    // Create health bar if enemy has more than 1 HP
    if (maxHealth > 1) {
      _createHealthBar();
    }

    // Spawn at position within road bounds
    final centerX = gameRef.size.x / 2;
    final leftBound = centerX - gameRef.roadWidth / 2 + radius * 2;
    final rightBound = centerX + gameRef.roadWidth / 2 - radius * 2;
    final headerHeight = 80.0;

    final spawnX = spawnXPercent != null
        ? leftBound + spawnXPercent! * (rightBound - leftBound)
        : leftBound + _random.nextDouble() * (rightBound - leftBound);
    position = Vector2(spawnX, headerHeight - radius * 2);
  }

  void _createHealthBar() {
    // Health bar background (black)
    healthBarBackground = RectangleComponent(
      size: Vector2(radius * 2, 4),
      position: Vector2(0, -6), // Above the enemy
      paint: Paint()..color = Colors.black,
    );
    add(healthBarBackground!);

    // Health bar foreground (start with green)
    healthBarForeground = RectangleComponent(
      size: Vector2(radius * 2, 4),
      position: Vector2(0, -6),
      paint: Paint()..color = Colors.green,
    );
    add(healthBarForeground!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move enemy downward
    position.y += getSpeed() * dt;

    // Remove enemy when it goes off-screen
    if (position.y > gameRef.size.y + radius) {
      removeFromParent();
    }
  }

  // Can be overridden by subclasses for different speeds
  double getSpeed() => baseSpeed;

  // Handle taking damage
  void takeDamage(int damage) {
    currentHealth -= damage;

    // Update health bar if it exists
    if (healthBarForeground != null && maxHealth > 1) {
      final healthPercentage = currentHealth / maxHealth;
      healthBarForeground!.size.x = (radius * 2) * healthPercentage;

      // Change health bar color based on health
      if (healthPercentage > 0.6) {
        healthBarForeground!.paint = Paint()..color = Colors.green;
      } else if (healthPercentage > 0.3) {
        healthBarForeground!.paint = Paint()..color = Colors.yellow;
      } else {
        healthBarForeground!.paint = Paint()..color = Colors.red;
      }
    }

    // Remove enemy if health reaches 0
    if (currentHealth <= 0) {
      onDestroyed();
      removeFromParent();
    }
  }

  // Called when enemy escapes (reaches bottom)
  void onEscaped() {
    // Deal damage equal to max health
    gameRef.takeDamage(maxHealth);
  }

  // Called when enemy is destroyed - can be overridden
  void onDestroyed() {
    // Notify game about kill
    gameRef.onSoldierKilled();

    // Spawn upgrade points if configured
    _spawnUpgradePoints();
  }

  void _spawnUpgradePoints() {
    if (dropUpgradePoints <= 0) return;

    final centerX = position.x + radius;
    final centerY = position.y + radius;

    for (int i = 0; i < dropUpgradePoints; i++) {
      // Random spread in a small radius for multiple UPs
      final randomRadius = dropUpgradePoints > 1 ? _random.nextDouble() * 15.0 : 0.0;
      final randomAngle = _random.nextDouble() * 2 * pi;
      final offsetX = randomRadius * cos(randomAngle);
      final offsetY = randomRadius * sin(randomAngle);
      final spawnPos = Vector2(centerX + offsetX, centerY + offsetY);
      final up = UpgradePoint(spawnPosition: spawnPos);
      gameRef.add(up);
    }
  }

  // Called when player collides with enemy
  void onPlayerCollision() {
    // Deal fixed damage to player
    gameRef.takeDamage(1);

    // Destroy enemy if configured (default true, false for bosses)
    if (destroyedOnPlayerCollision) {
      onDestroyed(); // Count as kill and drop UP
      removeFromParent();
    }
  }
}
