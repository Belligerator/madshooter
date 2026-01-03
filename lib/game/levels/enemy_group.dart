import 'dart:math';

import 'package:flame/components.dart';

import '../shooting_game.dart';
import '../components/upgrade_point.dart';

/// Tracks a group of enemies spawned from the same event.
/// UPs only drop when ALL enemies in the group are killed.
/// If any enemy escapes, the group's drop is lost.
class EnemyGroup {
  static final Random _random = Random();

  final String groupId;
  final int totalCount;
  final int dropUpgradePoints;
  final ShootingGame gameRef;

  int _killedCount = 0;
  int _escapedCount = 0;
  bool _dropAwarded = false;

  EnemyGroup({
    required this.groupId,
    required this.totalCount,
    required this.dropUpgradePoints,
    required this.gameRef,
  });

  /// Called when an enemy in this group is killed by the player
  void onEnemyKilled(Vector2 position) {
    _killedCount++;
    _checkGroupComplete(position);
  }

  /// Called when an enemy in this group escapes (leaves screen)
  void onEnemyEscaped() {
    _escapedCount++;
    // Group is now failed - no drop possible
  }

  void _checkGroupComplete(Vector2 lastKillPosition) {
    // All enemies accounted for?
    if (_killedCount + _escapedCount != totalCount) return;

    // Drop only if ALL were killed (none escaped)
    if (_killedCount == totalCount && !_dropAwarded && dropUpgradePoints > 0) {
      _dropAwarded = true;
      _spawnGroupDrop(lastKillPosition);
    }
  }

  void _spawnGroupDrop(Vector2 position) {
    for (int i = 0; i < dropUpgradePoints; i++) {
      // Random spread in a small radius for multiple UPs
      final randomRadius = dropUpgradePoints > 1 ? _random.nextDouble() * 15.0 : 0.0;
      final randomAngle = _random.nextDouble() * 2 * pi;
      final offsetX = randomRadius * cos(randomAngle);
      final offsetY = randomRadius * sin(randomAngle);
      final spawnPos = Vector2(position.x + offsetX, position.y + offsetY);
      final up = UpgradePoint(spawnPosition: spawnPos);
      gameRef.world.add(up);
    }
  }

  /// Whether all enemies in this group have been accounted for (killed or escaped)
  bool get isComplete => (_killedCount + _escapedCount) == totalCount;

  /// Whether the group was successful (all killed, none escaped)
  bool get isSuccessful => _killedCount == totalCount && isComplete;
}
