import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../shooting_game.dart';
import '../upgrade_point.dart';
import 'behaviors/movement_behavior.dart';

abstract class BaseEnemy extends CircleComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double baseSpeed = 30.0;
  static final Random _random = Random();

  final double outOfBoundsThreshold = 5.0;

  int maxHealth;
  int currentHealth;
  Color enemyColor;
  double enemyRadius;
  double? spawnXPercent; // Optional: 0.0-1.0 percentage of road width
  double spawnYOffset; // Optional: Offset for Y spawn position (negative moves up)
  int dropUpgradePoints; // Number of UP to drop when destroyed
  bool destroyedOnPlayerCollision; // Can enemy be destroyed on collision (false for bosses)
  MovementBehavior? movementBehavior; // Optional choreography movement

  RectangleComponent? healthBarBackground;
  RectangleComponent? healthBarForeground;

  BaseEnemy({
    required this.maxHealth,
    required this.enemyColor,
    required this.enemyRadius,
    this.spawnXPercent,
    this.spawnYOffset = 0.0,
    this.dropUpgradePoints = 0,
    this.destroyedOnPlayerCollision = true,
    this.movementBehavior,
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

    // Spawn at position within full screen bounds
    // Note: CircleComponent position is top-left of bounding box, so we use diameter (radius * 2)
    final screenLeft = 0.0;
    final screenRight = game.gameWidth;
    final diameter = radius * 2;

    // Calculate spawn X
    double spawnX;
    if (spawnXPercent != null) {
      // Map 0-1 to screen width, then clamp so enemy stays fully inside
      spawnX = screenLeft + spawnXPercent! * (game.gameWidth - diameter);
    } else {
      // Random position within valid bounds
      spawnX = screenLeft + _random.nextDouble() * (screenRight - screenLeft - diameter);
    }

    spawnX = spawnX.clamp(screenLeft, screenRight - diameter);
    // Spawn at top of game world (Y=0 is now below header in world coordinates)
    // Apply optional Y offset (negative values move further up/off-screen)
    position = Vector2(spawnX, -diameter + spawnYOffset);

    // Initialize movement behavior if present
    // Behavior bounds keep enemy fully inside screen (position is top-left)
    movementBehavior?.initialize(
      screenWidth: game.gameWidth,
      screenHeight: game.gameHeight,
      roadLeftBound: 0.0,
      roadRightBound: game.gameWidth - diameter,
      getPlayerPosition: () => game.player.position,
    );
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

    // Use movement behavior if present, otherwise linear descent
    if (movementBehavior != null) {
      final velocity = movementBehavior!.getVelocity(position, dt, getSpeed());
      position += velocity * dt;
    } else {
      // Default: move enemy downward
      position.y += getSpeed() * dt;
    }

    // Clamp x within screen bounds
    final diameter = radius * 2;
    position.x = position.x.clamp(0.0, game.gameWidth - diameter);

    // Remove enemy when it goes off-screen
    // When it crosses the bottom threshold, also count as escape
    if (position.y > game.gameHeight - outOfBoundsThreshold) {
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
    game.takeDamage(maxHealth);
  }

  // Called when enemy is destroyed - can be overridden
  void onDestroyed() {
    // Notify game about kill
    game.onSoldierKilled();

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
