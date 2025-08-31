import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';
import '../upgrade_config.dart';

enum BarrelType {
  bulletSize(Colors.brown, 0.1, 'Bullet Size', 0.5),        // 50% spawn chance - common
  fireRate(Colors.orange, 1.0, 'Fire Rate', 0.3),           // 30% spawn chance - uncommon
  ally(Colors.green, 1.0, 'Ally', 0.2);                     // 20% spawn chance - rare

  const BarrelType(this.color, this.upgradeValue, this.displayName, this.spawnProbability);

  final Color color;
  final double upgradeValue;
  final String displayName;
  final double spawnProbability; // 0.0 to 1.0 chance of spawning this type

  // Get max multiplier from config
  double get maxMultiplier {
    switch (this) {
      case BarrelType.bulletSize:
        return UpgradeConfig.maxBulletSizeMultiplier;
      case BarrelType.fireRate:
        return UpgradeConfig.maxFireRateMultiplier;
      case BarrelType.ally:
        return UpgradeConfig.maxAllyCount; // Max number of allies
    }
  }

  // Static method to select barrel type based on probability
  static BarrelType getRandomBarrelType(Random random) {
    final randomValue = random.nextDouble();

    // Create weighted selection based on probabilities
    double cumulativeProbability = 0.0;

    for (final barrelType in BarrelType.values) {
      cumulativeProbability += barrelType.spawnProbability;
      if (randomValue <= cumulativeProbability) {
        return barrelType;
      }
    }

    // Fallback to first barrel type if something goes wrong
    return BarrelType.bulletSize;
  }
}

class Barrel extends RectangleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 20.0;
  static const int maxHealth = 8;
  static const double spawnInterval = 5.0; // Spawn barrel every 5 seconds
  static final Random _random = Random();

  final BarrelType type;
  int currentHealth = maxHealth;
  late RectangleComponent healthBarBackground;
  late RectangleComponent healthBarForeground;

  Barrel({required this.type});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create barrel rectangle
    size = Vector2(25, 30);

    // Set barrel color from enum
    paint = Paint()..color = type.color;

    // Set priority to render above road but below player
    priority = 75;

    // Add collision detection
    add(RectangleHitbox());

    // Create health bar background (black)
    healthBarBackground = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -6), // Position above the barrel
      paint: Paint()..color = Colors.black,
    );
    add(healthBarBackground);

    // Create health bar foreground (start with green)
    healthBarForeground = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -6),
      paint: Paint()..color = Colors.green,
    );
    add(healthBarForeground);

    // Spawn at random position within RIGHT HALF of road bounds
    final centerX = gameRef.size.x / 2;
    final leftBound = centerX; // Start from center of road
    final rightBound = centerX + gameRef.roadWidth / 2 - size.x; // Use gameRef.roadWidth
    final headerHeight = 80.0;

    // Random X position within RIGHT half of road
    final randomX = leftBound + _random.nextDouble() * (rightBound - leftBound);
    position = Vector2(randomX, headerHeight - size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move barrel downward at road speed
    position.y += speed * dt;

    // Remove barrel when it goes off-screen (bottom)
    if (position.y > gameRef.size.y + size.y) {
      removeFromParent();
    }
  }

  // Called when barrel is hit by a bullet
  void takeDamage(int damage) {
    currentHealth -= damage;

    // Update health bar
    final healthPercentage = currentHealth / maxHealth;
    healthBarForeground.size.x = size.x * healthPercentage;

    // Change health bar color based on health
    if (healthPercentage > 0.6) {
      healthBarForeground.paint = Paint()..color = Colors.green;
    } else if (healthPercentage > 0.3) {
      healthBarForeground.paint = Paint()..color = Colors.yellow;
    } else {
      healthBarForeground.paint = Paint()..color = Colors.red;
    }

    // Destroy barrel if health reaches 0
    if (currentHealth <= 0) {
      _dropUpgrade();
      removeFromParent();
    }
  }

  void _dropUpgrade() {
    // Apply upgrade using enum data with max limits from config
    switch (type) {
      case BarrelType.bulletSize:
        final applied = gameRef.upgradeBulletSize(type.upgradeValue);
        break;
      case BarrelType.fireRate:
        final applied = gameRef.upgradeFireRate(type.upgradeValue);
        break;
      case BarrelType.ally:
        final applied = gameRef.addAlly();
        break;
    }
  }
}