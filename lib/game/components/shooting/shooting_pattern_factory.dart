import 'package:flame/components.dart';
import 'shooting_pattern.dart';
import 'patterns/single_shot_pattern.dart';
import 'patterns/spread_pattern.dart';
import 'patterns/burst_pattern.dart';
import 'patterns/radial_pattern.dart';
import 'patterns/aimed_pattern.dart';

/// Factory for creating ShootingPatterns from JSON configuration
class ShootingPatternFactory {
  /// Create a ShootingPattern from a JSON map
  /// 
  /// Supported patterns:
  /// - `single`: Single shot straight down
  /// - `spread`: Fan of bullets
  /// - `burst`: Rapid succession shots
  /// - `radial`: 360-degree bullet circle
  /// - `aimed`: Targets the player
  static ShootingPattern fromJson(Map<String, dynamic> json) {
    final type = json['shooting'] as String? ?? 'single';
    final speedMultiplier = (json['speed_multiplier'] as num?)?.toDouble() ?? 1.0;
    
    Vector2? offset;
    if (json['offset_x'] != null || json['offset_y'] != null) {
      offset = Vector2(
        (json['offset_x'] as num?)?.toDouble() ?? 0.0,
        (json['offset_y'] as num?)?.toDouble() ?? 0.0,
      );
    }

    switch (type) {
      case 'single':
        return SingleShotPattern(
          offset: offset,
          speedMultiplier: speedMultiplier,
        );

      case 'spread':
        return SpreadPattern(
          bulletCount: json['bullet_count'] as int? ?? 3,
          spreadAngle: (json['spread_angle'] as num?)?.toDouble() ?? 30.0,
          offset: offset,
          speedMultiplier: speedMultiplier,
        );

      case 'burst':
        return BurstPattern(
          bulletCount: json['bullet_count'] as int? ?? 3,
          delayBetweenShots: (json['delay'] as num?)?.toDouble() ?? 0.1,
          offset: offset,
          speedMultiplier: speedMultiplier,
        );

      case 'radial':
        return RadialPattern(
          bulletCount: json['bullet_count'] as int? ?? 8,
          startAngle: (json['start_angle'] as num?)?.toDouble() ?? 0.0,
          offset: offset,
          speedMultiplier: speedMultiplier,
        );

      case 'aimed':
        return AimedPattern(
          offset: offset,
          speedMultiplier: speedMultiplier,
          accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
        );

      default:
        // Default to single shot
        return SingleShotPattern(offset: offset, speedMultiplier: speedMultiplier);
    }
  }

  /// Create a pattern by type name with default settings
  static ShootingPattern byType(String type) {
    return fromJson({'shooting': type});
  }
}
