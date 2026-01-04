import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../shooting_game.dart';
import '../../upgrade_point.dart';
import '../../explosion_effect.dart';
import '../behaviors/movement_behavior.dart';
import '../bosses/abilities/boss_ability.dart';

abstract class BaseEnemy extends SpriteComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double baseSpeed = 30.0;
  static final Random _random = Random();

  // Cached Paint objects for health bars (avoid allocations)
  static final Paint _greenPaint = Paint()..color = Colors.green;
  static final Paint _yellowPaint = Paint()..color = Colors.yellow;
  static final Paint _redPaint = Paint()..color = Colors.red;
  static final Paint _blackPaint = Paint()..color = Colors.black;

  final double outOfBoundsThreshold = 5.0;

  int maxHealth;
  int currentHealth;
  double healthBarWidth; // Width of the health bar
  double healthBarX; // X position offset for health bar (from sprite center)
  double healthBarY; // Y position offset for health bar (from sprite center)
  double? spawnXPercent; // Optional: 0.0-1.0 percentage of road width
  double spawnYOffset; // Optional: Offset for Y spawn position (negative moves up)
  int dropUpgradePoints; // Number of UP to drop when destroyed (legacy, use groupId instead)
  bool destroyedOnPlayerCollision; // Can enemy be destroyed on collision (false for bosses)
  bool clampToScreenBounds; // Whether to clamp X position to screen bounds
  MovementBehavior? movementBehavior; // Optional choreography movement
  String? groupId; // Group ID for conditional drops - UP only drops when all group members killed
  List<EnemyAbility> abilities; // Abilities active on this enemy
  bool isSpawned = false; // True if spawned by ability (no rewards - prevents farming)

  // Sprite configuration (to be provided by subclasses)
  String spritePath;
  Sprite? cachedSprite; // Pre-cached sprite for performance
  double baseWidth; // Display size in game
  double baseHeight; // Display size in game

  // Health bar rendering constants
  static const double _healthBarHeight = 4.0;
  static const double _healthBarYOffset = 10.0;

  // Callback for pool release (set by EnemyPool)
  void Function(BaseEnemy)? onPoolRelease;

  BaseEnemy({
    required this.maxHealth,
    required this.healthBarWidth,
    required this.healthBarX,
    required this.healthBarY,
    required this.spritePath,
    required this.baseWidth,
    required this.baseHeight,
    this.cachedSprite,
    this.spawnXPercent,
    this.spawnYOffset = 0.0,
    this.dropUpgradePoints = 0,
    this.destroyedOnPlayerCollision = true,
    this.clampToScreenBounds = true,
    this.movementBehavior,
    this.groupId,
    this.abilities = const [],
  }) : currentHealth = maxHealth;

  // Abstract method: subclasses must define their own hitboxes
  void addHitboxes();

  @override
  Future<void> onLoad() async {
    super.onLoad();
    debugMode = true;

    // Use pre-cached sprite if available, otherwise load (fallback)
    sprite = cachedSprite ?? await game.loadSprite(spritePath);
    size = Vector2(baseWidth, baseHeight);
    anchor = Anchor.center;

    // Set priority to render below player
    priority = 50;

    // Let subclass define hitboxes
    addHitboxes();

    // Health bars are now drawn directly in render() - no components needed

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

    // Activate abilities (simulate phase enter for regular enemies)
    for (final ability in abilities) {
      ability.onPhaseEnter(this);
    }
  }

  // Draw health bar directly on canvas (no child components needed)
  void _drawHealthBar(Canvas canvas) {
    if (maxHealth <= 1) return;

    final healthPercent = currentHealth / maxHealth;
    final barY = healthBarY - _healthBarYOffset;

    // Background (black)
    canvas.drawRect(
      Rect.fromLTWH(healthBarX, barY, healthBarWidth, _healthBarHeight),
      _blackPaint,
    );

    // Foreground (colored based on health)
    final foregroundWidth = healthBarWidth * healthPercent;
    final healthPaint = healthPercent > 0.6
        ? _greenPaint
        : healthPercent > 0.3
        ? _yellowPaint
        : _redPaint;

    if (foregroundWidth > 0) {
      canvas.drawRect(Rect.fromLTWH(healthBarX, barY, foregroundWidth, _healthBarHeight), healthPaint);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawHealthBar(canvas);
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

    // Update abilities
    if (abilities.isNotEmpty) {
      // print('BaseEnemy.update: Updating ${abilities.length} abilities');
      for (final ability in abilities) {
        ability.update(dt, this);
      }
    }

    // Clamp x within screen bounds (using center anchor)
    if (clampToScreenBounds) {
      position.x = position.x.clamp(size.x / 2, game.gameWidth - size.x / 2);
    }

    // Remove enemy when it goes off-screen
    // When it crosses the bottom threshold, also count as escape
    if (position.y > game.gameHeight + size.y / 2 + outOfBoundsThreshold) {
      _onEscaped();
      removeFromParent();
    }
  }

  // Can be overridden by subclasses for different speeds
  double getSpeed() => baseSpeed;

  // Called when enemy escapes (leaves screen without being killed)
  void _onEscaped() {
    if (groupId != null) {
      game.levelManager.onEnemyGroupMemberEscaped(groupId!);
    }
  }

  /// Activate enemy for spawning (used by object pool)
  /// Resets runtime state and configures spawn parameters
  void activate({
    double? spawnXPercent,
    double spawnYOffset = 0.0,
    String? groupId,
    MovementBehavior? movementBehavior,
    List<EnemyAbility>? abilities,
    bool isSpawned = false,
  }) {
    // Exit old abilities
    for (final ability in this.abilities) {
      ability.onPhaseExit(this);
    }

    // Update spawn parameters
    this.spawnXPercent = spawnXPercent;
    this.spawnYOffset = spawnYOffset;
    this.groupId = groupId;
    this.movementBehavior = movementBehavior;
    this.abilities = abilities ?? [];
    this.isSpawned = isSpawned;
    // print('BaseEnemy.activate: Set ${this.abilities.length} abilities');

    // Reset runtime state
    currentHealth = maxHealth;
    priority = 50;

    // Calculate spawn position
    final screenRight = game.gameWidth;
    double spawnX;
    if (this.spawnXPercent != null) {
      spawnX = this.spawnXPercent! * game.gameWidth;
    } else {
      spawnX = _random.nextDouble() * screenRight;
    }
    spawnX = spawnX.clamp(size.x / 2, screenRight - size.x / 2);
    position = Vector2(spawnX, -size.y / 2 + spawnYOffset);

    // Initialize movement behavior if present
    movementBehavior?.initialize(
      screenWidth: game.gameWidth,
      screenHeight: game.gameHeight,
      roadLeftBound: size.x / 2,
      roadRightBound: game.gameWidth - size.x / 2,
      getPlayerPosition: () => game.player.position,
    );

    // Activate new abilities
    for (final ability in this.abilities) {
      ability.onPhaseEnter(this);
    }
  }

  /// Deactivate enemy and prepare for pool reuse
  void deactivate() {
    // Exit abilities
    for (final ability in abilities) {
      ability.onPhaseExit(this);
    }
    // Clear movement behavior to allow garbage collection
    movementBehavior = null;
    groupId = null;
    abilities = [];
  }

  @override
  void onRemove() {
    // Exit abilities
    for (final ability in abilities) {
      ability.onPhaseExit(this);
    }
    super.onRemove();
    // Notify pool to release this enemy for reuse
    onPoolRelease?.call(this);
  }

  // Handle taking damage
  void takeDamage(int damage) {
    currentHealth -= damage;
    priority++;

    // Health bar is drawn in render() based on currentHealth - no component update needed

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

    // Skip rewards for spawned enemies (prevent farming)
    if (isSpawned) return;

    // Notify game about kill
    game.onSoldierKilled();

    // Notify group about kill (group handles UP drops)
    if (groupId != null) {
      game.levelManager.onEnemyGroupMemberKilled(groupId!, position.clone());
    } else {
      // Legacy: spawn UP directly for non-grouped enemies (e.g., barrels)
      _spawnUpgradePoints();
    }
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
