// lib/game/levels/level_manager.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:madshooter/game/game_config.dart';
import '../shooting_game.dart';
import '../components/enemies/basic_soldier.dart';
import '../components/enemies/heavy_soldier.dart';
import '../components/enemies/behaviors/behavior_factory.dart';
import '../components/barrel.dart';
import 'level_data.dart';
import 'level_event.dart';
import 'level_state.dart';

class LevelManager {
  final ShootingGame gameRef;

  LevelData? currentLevel;
  LevelState levelState = LevelState.notStarted;

  double levelTime = 0.0;
  int currentEventIndex = 0;

  // Level progress tracking
  int levelKills = 0;
  int levelDamage = 0;
  int totalEnemiesSpawned = 0;
  int _pendingSpawns = 0;
  bool _playerDead = false; // Track if player has died

  LevelManager(this.gameRef);

  // Static method to load level data without game reference (for UI purposes)
  static Future<LevelData?> loadLevelData(int levelId) async {
    try {
      if (levelId > GameConfig.maxLevel) {
        print('Level $levelId exceeds max level ${GameConfig.maxLevel}');
        return null;
      }
      
      final jsonString = await rootBundle.loadString('assets/levels/level_$levelId.json');
      final jsonData = json.decode(jsonString);
      return LevelData.fromJson(jsonData);
    } catch (e) {
      print('Error loading level $levelId: $e');
      return null;
    }
  }

  Future<void> loadLevel(int levelId) async {
    try {
      if (levelId > GameConfig.maxLevel) {
        print('Level $levelId exceeds max level ${GameConfig.maxLevel}');
        return;
      }

      final jsonString = await rootBundle.loadString('assets/levels/level_$levelId.json');
      final jsonData = json.decode(jsonString);
      currentLevel = LevelData.fromJson(jsonData);

      _resetLevelState();
      print('Level ${currentLevel!.name} loaded successfully');
    } catch (e) {
      print('Error loading level $levelId: $e');
    }
  }

  void startLevel() {
    if (currentLevel == null) return;

    levelState = LevelState.running;
    levelTime = 0.0;
    currentEventIndex = 0;

    // Apply starting conditions
    _applyStartingConditions();

    print('Starting level: ${currentLevel!.name}');
  }

  void update(double dt) {
    if (levelState != LevelState.running || currentLevel == null) return;

    levelTime += dt;

    // Process level events
    _processEvents();

    // Check victory conditions
    _checkVictoryConditions();
  }

  void _processEvents() {
    if (currentLevel == null || currentEventIndex >= currentLevel!.events.length) return;

    final event = currentLevel!.events[currentEventIndex];

    // Check if it's time to trigger this event
    if (levelTime >= event.timestamp) {
      _executeEvent(event);
      currentEventIndex++;
    }
  }

  void _executeEvent(LevelEvent event) {
    switch (event.type) {
      case 'spawn_enemy':
        _spawnEnemyEvent(event.parameters, event.spawnX);
        break;
      case 'spawn_barrel':
        _spawnBarrelEvent(event.parameters, event.spawnX);
        break;
      case 'message':
        _showMessageEvent(event.parameters);
        break;
      default:
        print('Unknown event type: ${event.type}');
    }
  }

  void _spawnEnemyEvent(Map<String, dynamic> params, double? spawnX) {
    final enemyType = params['enemy_type'] as String;
    final count = params['count'] as int? ?? 1;
    final spawnPattern = params['spawn_pattern'] as String? ?? 'single';
    final dropUp = params['drop_up'] as int? ?? 0;
    final spawnInterval = (params['spawn_interval'] as num?)?.toDouble() ?? 0.5;
    final random = Random();

    // Increment pending spawns for the total count of enemies to be spawned
    _pendingSpawns += count;

    for (int i = 0; i < count; i++) {
      void spawn() {
        if (levelState != LevelState.running) {
          _pendingSpawns--; // Decrement if we abort spawn
          return;
        }

        // Create NEW movement behavior for each enemy (behaviors have internal state)
        final movementBehavior = BehaviorFactory.fromJson(params);

        // Calculate random Y offset for spread pattern
        // Randomize between 0 and -50 pixels (further up off-screen) to spread them out vertically
        double yOffset = 0.0;
        if (spawnPattern == 'spread') {
          yOffset = -random.nextDouble() * 100.0;
        }

        totalEnemiesSpawned++; // Track total enemies for star calculation
        switch (enemyType) {
          case 'basic_soldier':
            final enemy = BasicSoldier(
              spawnXPercent: spawnX,
              spawnYOffset: yOffset,
              dropUpgradePoints: dropUp,
              movementBehavior: movementBehavior,
            );
            gameRef.spawnEnemy(enemy);
            break;
          case 'heavy_soldier':
            final enemy = HeavySoldier(
              spawnXPercent: spawnX,
              spawnYOffset: yOffset,
              dropUpgradePoints: dropUp,
              movementBehavior: movementBehavior,
            );
            gameRef.spawnEnemy(enemy);
            break;
        }
        
        _pendingSpawns--; // Decrement after successful spawn
      }

      if (spawnPattern == 'line') {
        Future.delayed(Duration(milliseconds: (spawnInterval * 1000 * i).toInt()), spawn);
      } else {
        spawn();
      }

      // Add small delay between spawns for spread pattern
      if (spawnPattern == 'spread' && i < count - 1) {
        // You could add a slight delay here if needed
      }
    }

    print('Spawned $count $enemyType enemies');
  }

  void _spawnBarrelEvent(Map<String, dynamic> params, double? spawnX) {
    final barrelTypeString = params['barrel_type'] as String;
    final dropUp = params['drop_up'] as int? ?? 0;

    BarrelType barrelType;
    switch (barrelTypeString) {
      case 'bullet_size':
        barrelType = BarrelType.bulletSize;
        break;
      case 'fire_rate':
        barrelType = BarrelType.fireRate;
        break;
      case 'ally':
        barrelType = BarrelType.ally;
        break;
      case 'upgrade_point':
        barrelType = BarrelType.upgradePoint;
        break;
      default:
        barrelType = BarrelType.bulletSize;
    }

    // For upgrade_point barrel, default to 1 UP if not specified
    final actualDropUp = barrelType == BarrelType.upgradePoint && dropUp == 0 ? 1 : dropUp;

    final barrel = Barrel(type: barrelType, spawnXPercent: spawnX, dropUpgradePoints: actualDropUp);
    gameRef.add(barrel);

    print('Spawned ${barrelType.displayName} barrel');
  }

  void _showMessageEvent(Map<String, dynamic> params) {
    final message = params['message'] as String;
    gameRef.showMessage(message);
  }

  void _checkVictoryConditions() {
    if (currentLevel == null || levelState != LevelState.running) return;

    // Don't check victory if player is dead (waiting for delayed failure)
    if (_playerDead) return;

    final conditions = currentLevel!.victoryConditions;

    // Check failure first - too much damage taken
    if (conditions.maxDamageTaken != null && levelDamage > conditions.maxDamageTaken!) {
      _completeLevelFailure();
      return;
    }

    // Victory: All events processed AND all enemies cleared AND no pending spawns
    final allEventsProcessed = currentEventIndex >= currentLevel!.events.length;
    final allEnemiesCleared = gameRef.enemiesAlive == 0;
    final noPendingSpawns = _pendingSpawns <= 0;

    if (allEventsProcessed && allEnemiesCleared && noPendingSpawns) {
      _completeLevelSuccess();
      return;
    }
  }

  void _completeLevelSuccess() {
    levelState = LevelState.completed;
    print('Level completed successfully!');
    // You can add UI celebration here
  }

  void _completeLevelFailure() {
    levelState = LevelState.failed;
    print('Level failed!');
    // You can add UI failure screen here
  }

  void _resetLevelState() {
    levelState = LevelState.notStarted;
    levelTime = 0.0;
    currentEventIndex = 0;
    levelKills = 0;
    levelDamage = 0;
    totalEnemiesSpawned = 0;
    _pendingSpawns = 0;
    _playerDead = false;
  }

  void _applyStartingConditions() {
    if (currentLevel == null) return;

    final startingConditions = currentLevel!.startingConditions;

    // Reset game state first
    gameRef.resetGameState();

    // Apply starting upgrades
    gameRef.bulletSizeMultiplier = startingConditions.bulletSizeMultiplier;
    gameRef.additionalFireRate = startingConditions.additionalFireRate;

    // Add starting allies
    for (int i = 0; i < startingConditions.allyCount; i++) {
      gameRef.addAlly();
    }

    // Update UI to reflect starting conditions
    gameRef.updateUpgradeLabels();

    print(
      'Applied starting conditions: Size ${startingConditions.bulletSizeMultiplier}x, Rate +${startingConditions.additionalFireRate}/s, Allies ${startingConditions.allyCount}',
    );
  }

  // Called by game when enemy is killed
  void onEnemyKilled() {
    levelKills++;
  }

  // Called by game when player takes damage
  void onDamageTaken(int damage) {
    levelDamage += damage;
  }

  // Called when player health reaches 0
  void onPlayerDeath() {
    if (levelState == LevelState.running) {
      // Set flag to prevent victory checks
      _playerDead = true;

      // Delay level failure to allow explosion animation to play
      Future.delayed(const Duration(milliseconds: 600), () {
        if (levelState == LevelState.running && _playerDead) {
          _completeLevelFailure();
        }
      });
    }
  }

  // Getters for UI
  double get progress {
    if (currentLevel?.victoryConditions.surviveDuration != null) {
      return (levelTime / currentLevel!.victoryConditions.surviveDuration!).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String get timeRemaining {
    if (currentLevel?.victoryConditions.surviveDuration != null) {
      final remaining = currentLevel!.victoryConditions.surviveDuration! - levelTime;
      return remaining.toStringAsFixed(1);
    }
    return '';
  }

  // Star rating getters - based on kill percentage
  int get starsEarned {
    if (levelState != LevelState.completed) return 0;
    int stars = 1; // Star 1: Level completion
    if (totalEnemiesSpawned == 0) return stars;

    final killPercent = (levelKills / totalEnemiesSpawned) * 100;
    if (killPercent >= 50) stars++; // Star 2: 50%+ kills
    if (killPercent >= 90) stars++; // Star 3: 90%+ kills
    return stars;
  }

  double get killPercentage => totalEnemiesSpawned > 0 ? (levelKills / totalEnemiesSpawned) * 100 : 0;
}
