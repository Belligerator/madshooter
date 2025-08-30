// lib/game/levels/level_starting_conditions.dart

class LevelStartingConditions {
  final double bulletSizeMultiplier;
  final double additionalFireRate; // Additional shots per second
  final int allyCount;

  LevelStartingConditions({
    this.bulletSizeMultiplier = 1.0,
    this.additionalFireRate = 0.0, // Default: no additional fire rate
    this.allyCount = 0,
  });

  factory LevelStartingConditions.fromJson(Map<String, dynamic> json) {
    return LevelStartingConditions(
      bulletSizeMultiplier: json['bullet_size_multiplier'] != null
          ? (json['bullet_size_multiplier'] as num).toDouble()
          : 1.0,
      additionalFireRate: json['additional_fire_rate'] != null ? (json['additional_fire_rate'] as num).toDouble() : 0.0,
      allyCount: json['ally_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bulletSizeMultiplier != 1.0) 'bullet_size_multiplier': bulletSizeMultiplier,
      if (additionalFireRate != 0.0) 'additional_fire_rate': additionalFireRate,
      if (allyCount > 0) 'ally_count': allyCount,
    };
  }
}
