// lib/game/levels/level_data.dart

import 'level_event.dart';
import 'victory_conditions.dart';
import 'level_starting_conditions.dart';

class LevelData {
  final int levelId;
  final String name;
  final double duration;
  final String description;
  final List<LevelEvent> events;
  final VictoryConditions victoryConditions;
  final LevelStartingConditions startingConditions;

  LevelData({
    required this.levelId,
    required this.name,
    required this.duration,
    required this.description,
    required this.events,
    required this.victoryConditions,
    required this.startingConditions,
  });

  factory LevelData.fromJson(Map<String, dynamic> json) {
    return LevelData(
      levelId: json['levelId'] as int,
      name: json['name'] as String,
      duration: (json['duration'] as num).toDouble(),
      description: json['description'] as String,
      events: (json['events'] as List)
          .map((e) => LevelEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      victoryConditions: VictoryConditions.fromJson(
          json['victory_conditions'] as Map<String, dynamic>),
      startingConditions: LevelStartingConditions.fromJson(
          json['starting_conditions'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'levelId': levelId,
      'name': name,
      'duration': duration,
      'description': description,
      'events': events.map((e) => e.toJson()).toList(),
      'victory_conditions': victoryConditions.toJson(),
      'starting_conditions': startingConditions.toJson(),
    };
  }
}