import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';
import '../upgrade_config.dart';
import 'upgrade_point.dart';

enum BarrelType {
  bulletSize(Colors.brown, 0.1, 'Bullet Size', 0.5),        // 50% spawn chance - common
  fireRate(Colors.orange, 1.0, 'Fire Rate', 0.3),           // 30% spawn chance - uncommon
  ally(Colors.green, 1.0, 'Ally', 0.2),                     // 20% spawn chance - rare
  upgradePoint(Colors.amber, 0.0, 'Upgrade Point', 0.0);    // Only spawned via JSON

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
        return UpgradeConfig.maxAllyCount;
      case BarrelType.upgradePoint:
        return 10.0; // Max UP
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

class Barrel extends RectangleComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double speed = 20.0;
  static const int maxHealth = 800;
  static final Random _random = Random();

  final BarrelType type;
  final double? spawnXPercent; // Optional: 0.0-1.0 percentage of road width
  final int dropUpgradePoints; // Number of UP to drop when destroyed
  int currentHealth = maxHealth;
  late RectangleComponent healthBarBackground;
  late RectangleComponent healthBarForeground;

  Barrel({required this.type, this.spawnXPercent, this.dropUpgradePoints = 0});

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

    // Spawn at position within full screen bounds
    final leftBound = size.x;
    final rightBound = game.gameWidth - size.x;

    // X position within screen (use percentage if provided, otherwise random)
    final spawnX = spawnXPercent != null
        ? leftBound + spawnXPercent! * (rightBound - leftBound)
        : leftBound + _random.nextDouble() * (rightBound - leftBound);
    // Spawn at top of game world (Y=0 is now below header in world coordinates)
    position = Vector2(spawnX, -size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move barrel downward at road speed
    position.y += speed * dt;

    // Remove barrel when it goes off-screen (bottom)
    if (position.y > game.gameHeight + size.y) {
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
        game.upgradeBulletSize(type.upgradeValue);
        break;
      case BarrelType.fireRate:
        game.upgradeFireRate(type.upgradeValue);
        break;
      case BarrelType.ally:
        game.addAlly();
        break;
      case BarrelType.upgradePoint:
        // UP barrel only drops upgrade points, no direct upgrade
        break;
    }

    // Spawn upgrade point collectibles
    _spawnUpgradePoints();
  }

  void _spawnUpgradePoints() {
    if (dropUpgradePoints <= 0) return;

    final centerX = position.x + size.x / 2;
    final centerY = position.y + size.y / 2;

    for (int i = 0; i < dropUpgradePoints; i++) {
      // Random spread in a small radius for multiple UPs
      final randomRadius = dropUpgradePoints > 1 ? _random.nextDouble() * 15.0 : 0.0;
      final randomAngle = _random.nextDouble() * 2 * pi;
      final offsetX = randomRadius * cos(randomAngle);
      final offsetY = randomRadius * sin(randomAngle);
      final spawnPos = Vector2(centerX + offsetX, centerY + offsetY);
      final up = UpgradePoint(spawnPosition: spawnPos);
      game.world.add(up);
    }
  }
}
