import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 2: Moves through a sequence of waypoints.
/// Uses normalized coordinates (0-1) for screen-size independence.
class WaypointBehavior extends MovementBehavior {
  /// Waypoints in normalized coordinates (0-1)
  final List<List<double>> waypoints;

  /// Speed multiplier for movement between waypoints
  final double speedMultiplier;

  /// Distance threshold to consider a waypoint reached
  final double waypointThreshold;

  /// Whether to continue falling straight down after completing waypoints
  final bool continueOnComplete;

  /// Current waypoint index
  int _currentWaypointIndex = 0;

  /// Whether all waypoints have been visited
  bool _isComplete = false;

  WaypointBehavior({
    required this.waypoints,
    this.speedMultiplier = 1.0,
    this.waypointThreshold = 5.0,
    this.continueOnComplete = true,
  }) : assert(waypoints.isNotEmpty);

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    if (_isComplete || _currentWaypointIndex >= waypoints.length) {
      _isComplete = true;
      return Vector2(0, continueOnComplete ? baseSpeed : 0); // Fall straight down after completion
    }

    // Get current target waypoint in screen coordinates
    final targetNormalized = waypoints[_currentWaypointIndex];
    final targetX = roadLeftBound + targetNormalized[0] * (roadRightBound - roadLeftBound);
    final targetY = targetNormalized[1] * screenHeight;
    final targetPosition = Vector2(targetX, targetY);

    // Calculate direction to waypoint
    final direction = targetPosition - currentPosition;
    final distance = direction.length;

    // Check if we've reached the waypoint
    if (distance < waypointThreshold) {
      _currentWaypointIndex++;

      // Check if we've completed all waypoints
      if (_currentWaypointIndex >= waypoints.length) {
        _isComplete = true;
        return Vector2(0, baseSpeed);
      }

      // Recursively get velocity for next waypoint
      return getVelocity(currentPosition, dt, baseSpeed);
    }

    // Normalize direction and apply speed
    direction.normalize();
    final speed = baseSpeed * speedMultiplier;

    return direction * speed;
  }

  @override
  bool get isComplete => _isComplete;

  @override
  void reset() {
    _currentWaypointIndex = 0;
    _isComplete = false;
  }
}
