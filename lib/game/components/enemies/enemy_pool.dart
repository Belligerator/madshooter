import 'package:flame/components.dart';
import 'base_enemy.dart';
import 'behaviors/movement_behavior.dart';

/// Object pool for enemy reuse - eliminates GC pressure from constant create/destroy
class EnemyPool<T extends BaseEnemy> {
  final List<T> _available = [];
  final List<T> _active = [];
  final T Function() _factory;
  final World _world;

  EnemyPool(this._factory, this._world, {int initialSize = 50}) {
    // Pre-populate pool
    for (int i = 0; i < initialSize; i++) {
      _available.add(_factory());
    }
  }

  /// Get an enemy from the pool, creating a new one if needed
  T acquire({
    double? spawnXPercent,
    double spawnYOffset = 0.0,
    int dropUpgradePoints = 0,
    MovementBehavior? movementBehavior,
  }) {
    final T enemy;
    if (_available.isEmpty) {
      enemy = _factory();
    } else {
      enemy = _available.removeLast();
    }

    _active.add(enemy);

    // Set up pool release callback
    enemy.onPoolRelease = (e) => _releaseInternal(e as T);

    // Add to world first (so game reference is available)
    _world.add(enemy);

    // Then configure and activate the enemy
    enemy.activate(
      spawnXPercent: spawnXPercent,
      spawnYOffset: spawnYOffset,
      dropUpgradePoints: dropUpgradePoints,
      movementBehavior: movementBehavior,
    );

    return enemy;
  }

  /// Internal release called from onRemove callback
  void _releaseInternal(T enemy) {
    if (_active.remove(enemy)) {
      enemy.deactivate();
      _available.add(enemy);
    }
  }

  /// Return an enemy to the pool for reuse
  void release(T enemy) {
    if (_active.remove(enemy)) {
      enemy.deactivate();
      _available.add(enemy);
    }
  }

  /// Release all active enemies back to the pool
  void releaseAll() {
    for (final enemy in _active.toList()) {
      release(enemy);
    }
  }

  /// Number of enemies currently active
  int get activeCount => _active.length;

  /// Number of enemies available in pool
  int get availableCount => _available.length;
}
