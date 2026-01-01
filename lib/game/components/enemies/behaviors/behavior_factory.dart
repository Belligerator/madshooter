import 'movement_behavior.dart';
import 'sine_behavior.dart';
import 'zigzag_behavior.dart';
import 'bezier_behavior.dart';
import 'waypoint_behavior.dart';
import 'track_player_behavior.dart';
import 'strategic_behavior.dart';

/// Factory for creating movement behaviors from JSON configuration.
class BehaviorFactory {
  /// Creates a movement behavior from JSON event data.
  /// Returns null if no movement is specified (linear descent).
  static MovementBehavior? fromJson(Map<String, dynamic> json) {
    final movement = json['movement'] as String?;

    if (movement == null) {
      return null; // No behavior = linear descent (backwards compatible)
    }

    switch (movement) {
      // Tier 1: Simple patterns
      case 'sine':
        return SineBehavior(
          amplitude: (json['amplitude'] as num?)?.toDouble() ?? 40.0,
          frequency: (json['frequency'] as num?)?.toDouble() ?? 0.5,
        );

      case 'zigzag':
        return ZigzagBehavior(
          segmentLength: (json['segment_length'] as num?)?.toDouble() ?? 60.0,
          horizontalSpeedMultiplier: (json['horizontal_speed'] as num?)?.toDouble() ?? 1.5,
          startDirection: json['start_direction'] as int?,
        );

      // Tier 2: Path-based
      case 'bezier':
        final pathData = json['path'] as List<dynamic>?;
        if (pathData == null || pathData.length < 2) {
          return null; // Invalid bezier path
        }
        final controlPoints = pathData
            .map((p) => (p as List<dynamic>).map((v) => (v as num).toDouble()).toList())
            .toList();
        return BezierBehavior(controlPoints: controlPoints, duration: (json['duration'] as num?)?.toDouble() ?? 4.0);

      case 'waypoints':
        final waypointData = json['waypoints'] as List<dynamic>?;
        if (waypointData == null || waypointData.isEmpty) {
          return null; // Invalid waypoints
        }
        final waypoints = waypointData
            .map((p) => (p as List<dynamic>).map((v) => (v as num).toDouble()).toList())
            .toList();
        return WaypointBehavior(
          waypoints: waypoints,
          continueOnComplete: json['continue_on_complete'] as bool? ?? true,
          speedMultiplier: (json['speed_multiplier'] as num?)?.toDouble() ?? 1.0,
        );

      // Tier 3: Adaptive
      case 'track_player':
        return TrackPlayerBehavior(
          reactionSpeed: (json['reaction_speed'] as num?)?.toDouble() ?? 0.0,
          maxHorizontalSpeedMultiplier: (json['max_horizontal_speed'] as num?)?.toDouble() ?? 2.0,
        );

      case 'strategic':
        final strategyStr = json['strategy'] as String? ?? 'hover';
        StrategyType strategy;
        switch (strategyStr) {
          case 'flank':
            strategy = StrategyType.flank;
            break;
          case 'orbit':
            strategy = StrategyType.orbit;
            break;
          case 'hover':
          default:
            strategy = StrategyType.hover;
        }
        return StrategicBehavior(
          strategy: strategy,
          targetY: (json['target_y'] as num?)?.toDouble() ?? 0.2,
          approachSpeed: (json['approach_speed'] as num?)?.toDouble() ?? 1,
          continueOnComplete: json['continue_on_complete'] as bool? ?? true,
          orbitRadius: (json['orbit_radius'] as num?)?.toDouble() ?? 50.0,
          orbitSpeed: (json['orbit_speed'] as num?)?.toDouble() ?? 1.0,
        );

      default:
        return null; // Unknown movement type
    }
  }
}
