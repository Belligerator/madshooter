import 'dart:math';

import 'package:flame/components.dart';

import '../../enemies/base_enemy.dart';
import '../../behaviors/spawn_animation_behavior.dart';
import 'boss_ability.dart';

/// Ability to spawn minions around any enemy (regular enemies, mini-bosses, major bosses)
class SpawnMinionsAbility extends EnemyAbility {
  final String enemyType;
  final int count;
  final double interval;
  final double spreadRadius;
  final bool spawnOnEnter;
  final int? maxTotalEnemies; // Maximum alive enemies at any time (null = unlimited)

  double _timer = 0;
  final Set<BaseEnemy> _spawnedEnemies = {}; // Track currently alive spawned enemies
  static final Random _random = Random();

  SpawnMinionsAbility({
    required this.enemyType,
    required this.count,
    this.interval = 0,
    this.spreadRadius = 100,
    this.spawnOnEnter = true,
    this.maxTotalEnemies = 10, // null = unlimited enemies
  });

  @override
  void onPhaseEnter(BaseEnemy enemy) {
    // print('SpawnMinionsAbility: onPhaseEnter called');
    _timer = 0;
    _spawnedEnemies.clear(); // Clear tracking set
    if (spawnOnEnter && !_hasReachedSpawnLimit()) {
      _spawn(enemy);
    }
  }

  @override
  void update(double dt, BaseEnemy enemy) {
    // Clean up dead/removed enemies from tracking
    _spawnedEnemies.removeWhere((spawned) => !spawned.isMounted);

    // print('_timer: $_timer / $interval, alive: ${_spawnedEnemies.length}');
    if (interval <= 0) return;
    if (_hasReachedSpawnLimit()) return; // Stop spawning if limit reached

    _timer += dt;
    if (_timer >= interval) {
      _timer = 0;
      _spawn(enemy);
    }
  }

  /// Check if we've reached the maximum alive enemies limit
  bool _hasReachedSpawnLimit() {
    if (maxTotalEnemies == null) return false;
    // Check current alive count, not total spawned
    return _spawnedEnemies.length >= maxTotalEnemies!;
  }

  @override
  void onPhaseExit(BaseEnemy enemy) {
    // Clean up references when ability exits
    _spawnedEnemies.clear();
  }

  /// Spawn minions in a circular pattern around the enemy
  void _spawn(BaseEnemy enemy) {
    // Calculate how many to spawn this cycle (accounting for alive count)
    int toSpawn = count;
    if (maxTotalEnemies != null) {
      final remaining = maxTotalEnemies! - _spawnedEnemies.length;
      toSpawn = toSpawn.clamp(0, remaining);
    }

    // Get summoner's center position for spawn animation
    final summonerCenter = enemy.position.clone();

    for (int i = 0; i < toSpawn; i++) {
      // Calculate target position in a circle around the enemy
      final angle = _random.nextDouble() * 2 * pi;
      final offsetX = cos(angle) * spreadRadius;
      final offsetY = sin(angle) * spreadRadius;
      final targetPos = enemy.position + Vector2(offsetX, offsetY);

      // Spawn at summoner's center with animation to target position
      final spawnXPercent = summonerCenter.x / enemy.game.gameWidth;

      // Create spawn animation behavior
      final spawnAnimation = SpawnAnimationBehavior(
        startPosition: summonerCenter.clone(),
        targetPosition: targetPos.clone(),
        duration: 0.8, // 0.8 second animation
      );

      // Spawn and capture reference
      final spawnedEnemy = enemy.game.levelManager.spawnEnemyDirect(
        enemyType: enemyType,
        spawnXPercent: spawnXPercent.clamp(0.1, 0.9),
        spawnYOffset: summonerCenter.y,
        behavior: spawnAnimation,
      );

      // Track the spawned enemy if returned
      if (spawnedEnemy != null) {
        _spawnedEnemies.add(spawnedEnemy);
      }
    }
  }
}
