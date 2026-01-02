import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../shooting_game.dart';
import '../upgrade_point.dart';
import '../explosion_effect.dart';
import 'behaviors/movement_behavior.dart';

abstract class BaseEnemy extends SpriteComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double baseSpeed = 30.0;
  static final Random _random = Random();

  final double outOfBoundsThreshold = 5.0;

  int maxHealth;
  int currentHealth;
  double healthBarWidth; // Width of the health bar
  double healthBarX; // X position offset for health bar (from sprite center)
  double healthBarY; // Y position offset for health bar (from sprite center)
  double? spawnXPercent; // Optional: 0.0-1.0 percentage of road width
  double spawnYOffset; // Optional: Offset for Y spawn position (negative moves up)
  int dropUpgradePoints; // Number of UP to drop when destroyed
  bool destroyedOnPlayerCollision; // Can enemy be destroyed on collision (false for bosses)
  MovementBehavior? movementBehavior; // Optional choreography movement

  // Sprite configuration (to be provided by subclasses)
  String spritePath;
  double baseWidth; // Display size in game
  double baseHeight; // Display size in game

  RectangleComponent? healthBarBackground;
  RectangleComponent? healthBarForeground;

  BaseEnemy({
    required this.maxHealth,
    required this.healthBarWidth,
    required this.healthBarX,
    required this.healthBarY,
    required this.spritePath,
    required this.baseWidth,
    required this.baseHeight,
    this.spawnXPercent,
    this.spawnYOffset = 0.0,
    this.dropUpgradePoints = 0,
    this.destroyedOnPlayerCollision = true,
    this.movementBehavior,
  }) : currentHealth = maxHealth;

  // Abstract method: subclasses must define their own hitboxes
  void addHitboxes();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // debugMode = true;

    // Load sprite
    sprite = await game.loadSprite(spritePath);
    size = Vector2(baseWidth, baseHeight);
    anchor = Anchor.center;

    // Set priority to render below player
    priority = 50;

    // Let subclass define hitboxes
    addHitboxes();

    // Create health bar if enemy has more than 1 HP
    if (maxHealth > 1) {
      _createHealthBar();
    }

    // Spawn at position within full screen bounds
    // Note: Using center anchor, so position is center of sprite
    final screenLeft = 0.0;
    final screenRight = game.gameWidth;

    // Calculate spawn X
    double spawnX;
    if (spawnXPercent != null) {
      // Map 0-1 to screen width
      spawnX = screenLeft + spawnXPercent! * game.gameWidth;
    } else {
      // Random position within valid bounds
      spawnX = screenLeft + _random.nextDouble() * (screenRight - screenLeft);
    }

    spawnX = spawnX.clamp(size.x / 2, screenRight - size.x / 2);
    // Spawn at top of game world (Y=0 is now below header in world coordinates)
    // Apply optional Y offset (negative values move further up/off-screen)
    position = Vector2(spawnX, -size.y / 2 + spawnYOffset);

    // Initialize movement behavior if present
    movementBehavior?.initialize(
      screenWidth: game.gameWidth,
      screenHeight: game.gameHeight,
      roadLeftBound: size.x / 2,
      roadRightBound: game.gameWidth - size.x / 2,
      getPlayerPosition: () => game.player.position,
    );
  }

  void _createHealthBar() {
    final barHeight = 4.0;
    final barYOffset = 10.0;

    // Health bar background (black)
    healthBarBackground = RectangleComponent(
      size: Vector2(healthBarWidth, barHeight),
      position: Vector2(healthBarX, healthBarY - barYOffset), // Centered horizontally
      paint: Paint()..color = Colors.black,
    );
    add(healthBarBackground!);

    // Health bar foreground (start with green)
    healthBarForeground = RectangleComponent(
      size: Vector2(healthBarWidth, barHeight),
      position: Vector2(healthBarX, healthBarY - barYOffset),
      paint: Paint()..color = Colors.green,
    );
    add(healthBarForeground!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Use movement behavior if present, otherwise linear descent
    if (movementBehavior != null) {
      final velocity = movementBehavior!.getVelocity(position, dt, getSpeed());
      position += velocity * dt;
    } else {
      // Default: move enemy downward
      position.y += getSpeed() * dt;
    }

    // Clamp x within screen bounds (using center anchor)
    position.x = position.x.clamp(size.x / 2, game.gameWidth - size.x / 2);

    // Update priority based on Y position (lower enemies render on top)
    // Base priority 50, add Y position scaled to 0-100 range
    priority = (50 + (position.y / game.gameHeight * 100).clamp(0.0, 100.0)).toInt();

    // Remove enemy when it goes off-screen
    // When it crosses the bottom threshold, also count as escape
    if (position.y > game.gameHeight + size.y / 2 + outOfBoundsThreshold) {
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
      healthBarForeground!.size.x = clampDouble(healthBarWidth * healthPercentage, 0, healthBarWidth);

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

  // Called when enemy is destroyed - can be overridden
  void onDestroyed() {
    // Spawn explosion effect at enemy center
    final explosion = ExplosionEffect(origin: position.clone());
    game.world.add(explosion);

    // Notify game about kill
    game.onSoldierKilled();

    // Spawn upgrade points if configured
    _spawnUpgradePoints();
  }

  void _spawnUpgradePoints() {
    if (dropUpgradePoints <= 0) return;

    // Position is already the center (using Anchor.center)
    final centerX = position.x;
    final centerY = position.y;

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

  // Called when player collides with enemy
  void onPlayerCollision() {
    // Deal fixed damage to player
    game.takeDamage(1);

    // Destroy enemy if configured (default true, false for bosses)
    if (destroyedOnPlayerCollision) {
      onDestroyed(); // Count as kill and drop UP
      removeFromParent();
    }
  }
}
