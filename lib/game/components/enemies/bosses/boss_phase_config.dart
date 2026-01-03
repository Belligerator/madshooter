import 'package:madshooter/game/components/enemies/behaviors/movement_behavior.dart';
import 'package:madshooter/game/components/shooting/shooting_pattern.dart';
import 'abilities/boss_ability.dart';

/// Configuration for a single boss phase
class BossPhaseConfig {
  /// Health threshold to enter this phase (1.0 = full health, 0.0 = dead)
  /// Phase activates when health drops TO or BELOW this threshold
  final double healthThreshold;
  
  /// Movement behavior for this phase (null = keep previous)
  final MovementBehavior? behavior;
  
  /// Shooting pattern for this phase
  final ShootingPattern? shootingPattern;
  
  /// Seconds between shots
  final double fireInterval;

  /// Abilities active during this phase
  final List<BossAbility> abilities;
  
  /// Callback when entering this phase (for visual effects, spawning minions, etc.)
  final void Function()? onEnter;

  const BossPhaseConfig({
    required this.healthThreshold,
    this.behavior,
    this.shootingPattern,
    this.fireInterval = 2.0,
    this.abilities = const [],
    this.onEnter,
  });
}
