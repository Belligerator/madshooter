import '../base_boss.dart';
import 'boss_ability.dart';

/// Ability to spawn minions around the boss
class SpawnMinionsAbility extends BossAbility {
  final String enemyType;
  final int count;
  final double interval;
  final double spreadRadius;
  final bool spawnOnEnter;

  double _timer = 0;

  SpawnMinionsAbility({
    required this.enemyType,
    required this.count,
    this.interval = 0,
    this.spreadRadius = 100,
    this.spawnOnEnter = true,
  });

  @override
  void onPhaseEnter(BaseBoss boss) {
    _timer = 0;
    if (spawnOnEnter) {
      _spawn(boss);
    }
  }

  @override
  void update(double dt, BaseBoss boss) {
    if (interval <= 0) return;

    _timer += dt;
    if (_timer >= interval) {
      _timer = 0;
      _spawn(boss);
    }
  }

  void _spawn(BaseBoss boss) {
    boss.spawnMinions(enemyType, count, spreadRadius: spreadRadius);
  }
}
