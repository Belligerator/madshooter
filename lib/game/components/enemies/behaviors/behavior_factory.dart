import 'movement_behavior.dart';
import 'sine_behavior.dart';
import 'zigzag_behavior.dart';
import 'bezier_behavior.dart';
import 'chained_bezier_behavior.dart';
import 'catmull_rom_behavior.dart';
import 'waypoint_behavior.dart';
import 'track_player_behavior.dart';
import 'strategic_behavior.dart';

/// Factory for creating movement behaviors from JSON configuration.
/// +-----------------+-------------------------------------------------+
/// | Behavior        | Use Case                                        |
/// +-----------------+-------------------------------------------------+
/// | sine            | Simple oscillating movement                     |
/// | zigzag          | Sharp back-and-forth movement                   |
/// | waypoints       | Linear point-to-point, sharp corners            |
/// | bezier          | Single curve (2-4 control points)               |
/// | chained_bezier  | Multiple connected curves with explicit control |
/// | catmull_rom     | Smooth curve through waypoints                  |
/// | track_player    | Adaptive tracking of player position            |
/// | strategic       | Complex strategies (flanking, orbiting, etc.)   |
/// +-----------------+-------------------------------------------------+
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

      case 'chained_bezier':
        final pathData = json['path'] as List<dynamic>?;
        if (pathData == null || pathData.length < 3) {
          return null; // Need at least 3 points
        }
        final points = pathData
            .map((p) => (p as List<dynamic>).map((v) => (v as num).toDouble()).toList())
            .toList();
        final smooth = json['smooth'] as bool? ?? false;
        // Validate point count for explicit mode (need 2n+1 points)
        if (!smooth && (points.length - 1) % 2 != 0) {
          return null; // Invalid point count for explicit mode
        }
        return ChainedBezierBehavior(
          points: points,
          duration: (json['duration'] as num?)?.toDouble() ?? 4.0,
          smooth: smooth,
          tension: (json['tension'] as num?)?.toDouble() ?? 0.5,
        );

      case 'catmull_rom':
        final waypointData = json['waypoints'] as List<dynamic>?;
        if (waypointData == null || waypointData.length < 2) {
          return null; // Need at least 2 waypoints
        }
        final waypoints = waypointData
            .map((p) => (p as List<dynamic>).map((v) => (v as num).toDouble()).toList())
            .toList();
        return CatmullRomBehavior(
          waypoints: waypoints,
          duration: (json['duration'] as num?)?.toDouble() ?? 4.0,
          tension: (json['tension'] as num?)?.toDouble() ?? 0.5,
          continueOnComplete: json['continue_on_complete'] as bool? ?? true,
        );

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
