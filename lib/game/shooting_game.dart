import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'components/player.dart';
import 'components/road.dart';
import 'components/virtual_joystick.dart';
import 'components/enemies/base_enemy.dart';
import 'components/enemies/basic_soldier.dart';
import 'components/enemies/heavy_soldier.dart';
import 'components/header.dart';
import 'components/barrel.dart';
import 'upgrade_config.dart';

class ShootingGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  late Player player;
  late Road road;
  late VirtualJoystick joystick;
  late Header header;

  // UI Layout constants
  static const double headerHeight = 80.0;
  final double roadWidth = 200.0; // Instance variable instead of static
  double safeAreaTop; // Changed to mutable for dynamic updates

  // Game state
  bool isPaused = false;

  // Spawning timers
  double _timeSinceLastBarrelSpawn = 0;
  double _timeSinceLastBasicSpawn = 0;
  double _timeSinceLastHeavySpawn = 0;

  final Random _random = Random();
  final List<BaseEnemy> _enemies = []; // Changed from _soldiers to _enemies

  // Game statistics
  int killCount = 0;
  int totalDamage = 0; // Changed from escapedCount

  // Weapon upgrades
  double bulletSizeMultiplier = 1.0;
  double fireRateMultiplier = 1.0;

  // Constructor to accept safe area padding
  ShootingGame({this.safeAreaTop = 0.0});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add road background
    road = Road();
    add(road);

    // Add player
    player = Player();
    add(player);

    // Add virtual joystick (moved to right side)
    joystick = VirtualJoystick(
      knob: CircleComponent(radius: 15, paint: Paint()..color = Colors.blue),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.grey.withOpacity(0.5)),
      margin: const EdgeInsets.only(right: 40, bottom: 40),
    );
    add(joystick);

    // Add header component (will render on top due to high priority)
    header = Header();
    add(header);
  }

  @override
  void update(double dt) {
    // Don't update if game is paused
    if (isPaused) return;

    super.update(dt);

    // Move player based on joystick input
    if (!joystick.delta.isZero()) {
      player.move(joystick.delta.x);
    }

    // Handle enemy spawning (separate for each type)
    _handleBasicSoldierSpawning(dt);
    _handleHeavySoldierSpawning(dt);

    // Handle barrel spawning
    _handleBarrelSpawning(dt);

    // Clean up dead enemies from our tracking list and check for escaped
    _enemies.removeWhere((enemy) {
      if (enemy.isRemoved) {
        return true; // Remove from tracking list
      }

      // Check if enemy escaped (reached bottom without being killed)
      if (enemy.position.y > size.y) {
        enemy.onEscaped(); // Deal damage based on enemy type
        return true; // Remove from tracking list
      }

      return false; // Keep in tracking list
    });
  }

  void _handleBasicSoldierSpawning(double dt) {
    _timeSinceLastBasicSpawn += dt;

    if (_timeSinceLastBasicSpawn >= BasicSoldier.spawnInterval) {
      _spawnBasicSoldiers();
      _timeSinceLastBasicSpawn = 0;
    }
  }

  void _handleHeavySoldierSpawning(double dt) {
    _timeSinceLastHeavySpawn += dt;

    if (_timeSinceLastHeavySpawn >= HeavySoldier.spawnInterval) {
      _spawnHeavySoldiers();
      _timeSinceLastHeavySpawn = 0;
    }
  }

  void _handleBarrelSpawning(double dt) {
    _timeSinceLastBarrelSpawn += dt;

    if (_timeSinceLastBarrelSpawn >= Barrel.spawnInterval) {
      _spawnBarrel();
      _timeSinceLastBarrelSpawn = 0;
    }
  }

  void _spawnBasicSoldiers() {
    for (int i = 0; i < BasicSoldier.soldiersPerSpawn; i++) {
      final enemy = BasicSoldier();
      _enemies.add(enemy);
      add(enemy);
    }
  }

  void _spawnHeavySoldiers() {
    for (int i = 0; i < HeavySoldier.soldiersPerSpawn; i++) {
      final enemy = HeavySoldier();
      _enemies.add(enemy);
      add(enemy);
    }
  }

  void _spawnBarrel() {
    // Use probability-based barrel type selection
    final barrelType = BarrelType.getRandomBarrelType(_random);

    final barrel = Barrel(type: barrelType);
    add(barrel);
  }

  // Called when a soldier is killed by bullet collision
  void onSoldierKilled() {
    killCount++;
    _updateLabels();
  }

  // Called when player takes damage from escaped enemies
  void takeDamage(int damage) {
    totalDamage += damage;
    _updateLabels();
  }

  void _updateLabels() {
    header.updateKills(killCount);
    header.updateDamage(totalDamage);
  }

  void _updateUpgradeLabels() {
    header.updateBulletSize(bulletSizeMultiplier);
    header.updateFireRate(fireRateMultiplier);
  }

  // Pause/Resume methods (called from Flutter widget)
  void pauseGame() {
    isPaused = true;
    pauseEngine(); // Stops the game loop
    print('Game paused');
  }

  void resumeGame() {
    isPaused = false;
    resumeEngine(); // Resumes the game loop
    print('Game resumed');
  }

  // Weapon upgrade methods with max limits from config
  bool upgradeBulletSize(double multiplier) {
    if (bulletSizeMultiplier >= UpgradeConfig.maxBulletSizeMultiplier) {
      return false; // Already at max
    }

    bulletSizeMultiplier = (bulletSizeMultiplier + multiplier).clamp(1.0, UpgradeConfig.maxBulletSizeMultiplier);
    _updateUpgradeLabels(); // Update UI
    return true; // Upgrade applied
  }

  bool upgradeFireRate(double multiplier) {
    if (fireRateMultiplier >= UpgradeConfig.maxFireRateMultiplier) {
      return false; // Already at max
    }

    fireRateMultiplier = (fireRateMultiplier + multiplier).clamp(1.0, UpgradeConfig.maxFireRateMultiplier);
    _updateUpgradeLabels(); // Update UI
    return true; // Upgrade applied
  }

  // Get current bullet size with upgrades applied
  Vector2 getBulletSize() {
    final baseSize = Vector2(UpgradeConfig.baseBulletWidth, UpgradeConfig.baseBulletHeight);
    return Vector2(baseSize.x * bulletSizeMultiplier, baseSize.y * bulletSizeMultiplier);
  }

  // Get current fire rate with upgrades applied
  double getFireRate() {
    return UpgradeConfig.baseFireRate / fireRateMultiplier; // Lower value = faster firing
  }

  // Helper method to get the game area height (excluding header and safe areas)
  double get gameAreaHeight => size.y - headerHeight - safeAreaTop;

  // Helper method to get the game area start position (including safe area)
  double get gameAreaTop => headerHeight + safeAreaTop;
}