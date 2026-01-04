import '../../base_enemy.dart';

/// Abstract base class for enemy abilities
/// Works for all enemy types: regular enemies, mini-bosses, and major bosses
///
/// Lifecycle:
/// - For regular enemies: onPhaseEnter called once during spawn, onPhaseExit called on death
/// - For bosses: onPhaseEnter/onPhaseExit called during phase transitions
abstract class EnemyAbility {
  /// Called when the ability activates
  /// For regular enemies: called once during spawn
  /// For bosses: called when entering a phase
  void onPhaseEnter(BaseEnemy enemy) {}

  /// Called every frame while active
  void update(double dt, BaseEnemy enemy) {}

  /// Called when the ability deactivates
  /// For regular enemies: called on death/despawn
  /// For bosses: called when exiting a phase
  void onPhaseExit(BaseEnemy enemy) {}
}
