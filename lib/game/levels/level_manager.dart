// lib/game/levels/level_manager.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../shooting_game.dart';
import '../components/enemies/basic_soldier.dart';
import '../components/enemies/heavy_soldier.dart';
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

  LevelManager(this.gameRef);

  // Static method to load level data without game reference (for UI purposes)
  static Future<LevelData?> loadLevelData(int levelId) async {
    try {
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
        _spawnEnemyEvent(event.parameters);
        break;
      case 'spawn_barrel':
        _spawnBarrelEvent(event.parameters);
        break;
      case 'message':
        _showMessageEvent(event.parameters);
        break;
      default:
        print('Unknown event type: ${event.type}');
    }
  }

  void _spawnEnemyEvent(Map<String, dynamic> params) {
    final enemyType = params['enemy_type'] as String;
    final count = params['count'] as int? ?? 1;
    final spawnPattern = params['spawn_pattern'] as String? ?? 'single';

    for (int i = 0; i < count; i++) {
      switch (enemyType) {
        case 'basic_soldier':
          final enemy = BasicSoldier();
          gameRef.add(enemy);
          break;
        case 'heavy_soldier':
          final enemy = HeavySoldier();
          gameRef.add(enemy);
          break;
      }

      // Add small delay between spawns for spread pattern
      if (spawnPattern == 'spread' && i < count - 1) {
        // You could add a slight delay here if needed
      }
    }

    print('Spawned $count $enemyType enemies');
  }

  void _spawnBarrelEvent(Map<String, dynamic> params) {
    final barrelTypeString = params['barrel_type'] as String;

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
      default:
        barrelType = BarrelType.bulletSize;
    }

    final barrel = Barrel(type: barrelType);
    gameRef.add(barrel);

    print('Spawned ${barrelType.displayName} barrel');
  }

  void _showMessageEvent(Map<String, dynamic> params) {
    final message = params['message'] as String;
    // You can implement UI message display here
    print('Level Message: $message');
  }

  void _checkVictoryConditions() {
    if (currentLevel == null || levelState != LevelState.running) return;

    final conditions = currentLevel!.victoryConditions;

    // Check if level duration completed
    if (conditions.surviveDuration != null &&
        levelTime >= conditions.surviveDuration!) {
      _completeLevelSuccess();
      return;
    }

    // Check if too much damage taken
    if (conditions.maxDamageTaken != null &&
        levelDamage > conditions.maxDamageTaken!) {
      _completeLevelFailure();
      return;
    }

    // Check if minimum kills reached (and all events processed)
    if (conditions.minKills != null &&
        levelKills >= conditions.minKills! &&
        currentEventIndex >= currentLevel!.events.length) {
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

    print('Applied starting conditions: Size ${startingConditions.bulletSizeMultiplier}x, Rate +${startingConditions.additionalFireRate}/s, Allies ${startingConditions.allyCount}');
  }

  // Called by game when enemy is killed
  void onEnemyKilled() {
    levelKills++;
  }

  // Called by game when player takes damage
  void onDamageTaken(int damage) {
    levelDamage += damage;
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
}