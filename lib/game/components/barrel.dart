import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';
import '../upgrade_config.dart';

enum BarrelType {
  bulletSize(Colors.brown, 0.1, 'Bullet Size'),
  fireRate(Colors.orange, 0.1, 'Fire Rate');

  const BarrelType(this.color, this.upgradeValue, this.displayName);

  final Color color;
  final double upgradeValue;
  final String displayName;

  // Get max multiplier from config
  double get maxMultiplier {
    switch (this) {
      case BarrelType.bulletSize:
        return UpgradeConfig.maxBulletSizeMultiplier;
      case BarrelType.fireRate:
        return UpgradeConfig.maxFireRateMultiplier;
    }
  }
}

class Barrel extends RectangleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 100.0; // Same as road scroll speed
  static const int maxHealth = 10;
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

    // Create health bar foreground (red)
    healthBarForeground = RectangleComponent(
      size: Vector2(size.x, 4),
      position: Vector2(0, -6),
      paint: Paint()..color = Colors.red,
    );
    add(healthBarForeground);

    // Spawn at random position within road bounds at top of game area
    final roadWidth = 200.0;
    final centerX = gameRef.size.x / 2;
    final leftBound = centerX - roadWidth / 2;
    final rightBound = centerX + roadWidth / 2 - size.x;
    final headerHeight = 80.0;

    // Random X position within road
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
        if (applied) {
          print('${type.displayName} upgrade! Bullets are now ${(type.upgradeValue * 100).toInt()}% bigger.');
        } else {
          print('${type.displayName} already at maximum level!');
        }
        break;
      case BarrelType.fireRate:
        final applied = gameRef.upgradeFireRate(type.upgradeValue);
        if (applied) {
          print('${type.displayName} upgrade! Shooting ${(type.upgradeValue * 100).toInt()}% faster.');
        } else {
          print('${type.displayName} already at maximum level!');
        }
        break;
    }
  }
}