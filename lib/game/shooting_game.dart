import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'components/player.dart';
import 'components/road.dart';
import 'components/virtual_joystick.dart';
import 'components/soldier.dart';
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
  double safeAreaTop; // Changed to mutable for dynamic updates

  // Game state
  bool isPaused = false;

  // Enemy spawning variables
  static const double spawnInterval = 5.0; // Spawn every 5 seconds
  static const int maxVisibleSoldiers = 50;
  static const int soldiersPerSpawn = 5;

  // Barrel spawning variables
  static const double barrelSpawnInterval = 15.0; // Spawn barrel every 15 seconds
  double _timeSinceLastBarrelSpawn = 0;

  double _timeSinceLastSpawn = 0;
  final Random _random = Random();
  final List<Soldier> _soldiers = [];

  // Game statistics
  int killCount = 0;
  int escapedCount = 0;

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

    // Handle enemy spawning
    _handleEnemySpawning(dt);

    // Handle barrel spawning
    _handleBarrelSpawning(dt);

    // Clean up dead soldiers from our tracking list and check for escaped
    _soldiers.removeWhere((soldier) {
      if (soldier.isRemoved) {
        return true; // Remove from tracking list
      }

      // Check if soldier escaped (reached bottom without being killed)
      if (soldier.position.y > size.y) {
        escapedCount++;
        _updateLabels();
        return true; // Remove from tracking list
      }

      return false; // Keep in tracking list
    });
  }

  void _handleEnemySpawning(double dt) {
    _timeSinceLastSpawn += dt;

    if (_timeSinceLastSpawn >= spawnInterval) {
      _spawnSoldiers();
      _timeSinceLastSpawn = 0;
    }
  }

  void _handleBarrelSpawning(double dt) {
    _timeSinceLastBarrelSpawn += dt;

    if (_timeSinceLastBarrelSpawn >= barrelSpawnInterval) {
      _spawnBarrel();
      _timeSinceLastBarrelSpawn = 0;
    }
  }

  void _spawnSoldiers() {
    // Don't spawn if we already have too many soldiers
    if (_soldiers.length >= maxVisibleSoldiers) {
      return;
    }

    // Calculate how many soldiers we can spawn
    final remainingSlots = maxVisibleSoldiers - _soldiers.length;
    final soldiersToSpawn = min(soldiersPerSpawn, remainingSlots);

    for (int i = 0; i < soldiersToSpawn; i++) {
      final soldier = Soldier();
      _soldiers.add(soldier);
      add(soldier);
    }

    print('Spawned $soldiersToSpawn soldiers. Total: ${_soldiers.length}');
  }

  void _spawnBarrel() {
    // Randomly choose barrel type
    final barrelType = _random.nextBool() ? BarrelType.bulletSize : BarrelType.fireRate;

    final barrel = Barrel(type: barrelType);
    add(barrel);

    print('Spawned ${barrelType.name} barrel');
  }

  // Called when a soldier is killed by bullet collision
  void onSoldierKilled() {
    killCount++;
    _updateLabels();
  }

  void _updateLabels() {
    header.updateKills(killCount);
    header.updateEscaped(escapedCount);
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

  // Manual pause/resume methods (for pause button if needed)
  void togglePause() {
    if (isPaused) {
      resumeGame();
    } else {
      pauseGame();
    }
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
