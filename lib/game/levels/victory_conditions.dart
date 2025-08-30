class VictoryConditions {
  final double? surviveDuration;
  final int? maxDamageTaken;
  final int? minKills;

  VictoryConditions({this.surviveDuration, this.maxDamageTaken, this.minKills});

  factory VictoryConditions.fromJson(Map<String, dynamic> json) {
    return VictoryConditions(
      surviveDuration: json['survive_duration'] != null ? (json['survive_duration'] as num).toDouble() : null,
      maxDamageTaken: json['max_damage_taken'] as int?,
      minKills: json['min_kills'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (surviveDuration != null) 'survive_duration': surviveDuration,
      if (maxDamageTaken != null) 'max_damage_taken': maxDamageTaken,
      if (minKills != null) 'min_kills': minKills,
    };
  }
}
