import 'boss_ability.dart';
import 'spawn_minions_ability.dart';

class AbilityFactory {
  static BossAbility fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'spawn_minions':
        return SpawnMinionsAbility(
          enemyType: json['enemy_type'] as String? ?? 'basic_soldier',
          count: json['count'] as int? ?? 3,
          interval: (json['interval'] as num?)?.toDouble() ?? 0.0,
          spreadRadius: (json['spread_radius'] as num?)?.toDouble() ?? 100.0,
          spawnOnEnter: json['spawn_on_enter'] as bool? ?? true,
        );
      default:
        throw ArgumentError('Unknown ability type: $type');
    }
  }
}
