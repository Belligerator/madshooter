import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 1: Sharp direction changes in a zigzag pattern while descending.
class ZigzagBehavior extends MovementBehavior {
  /// Vertical distance traveled before changing direction
  final double segmentLength;

  /// Horizontal speed multiplier relative to base speed
  final double horizontalSpeedMultiplier;

  /// Current horizontal direction: 1 = right, -1 = left
  int _direction = 1;

  /// Distance traveled in current segment
  double _segmentProgress = 0;

  /// Starting direction (randomized or set)
  final int? startDirection;

  ZigzagBehavior({
    this.segmentLength = 60.0,
    this.horizontalSpeedMultiplier = 1.5,
    this.startDirection,
  });

  @override
  void initialize({
    required double screenWidth,
    required double screenHeight,
    required double roadLeftBound,
    required double roadRightBound,
    Vector2 Function()? getPlayerPosition,
  }) {
    super.initialize(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      roadLeftBound: roadLeftBound,
      roadRightBound: roadRightBound,
      getPlayerPosition: getPlayerPosition,
    );

    // Set initial direction
    if (startDirection != null) {
      _direction = startDirection! >= 0 ? 1 : -1;
    }
  }

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    // Track vertical progress
    _segmentProgress += baseSpeed * dt;

    // Check if we need to change direction
    if (_segmentProgress >= segmentLength) {
      _direction *= -1;
      _segmentProgress = 0;
    }

    // Check road bounds and reverse if hitting edge
    final horizontalSpeed = baseSpeed * horizontalSpeedMultiplier * _direction;
    final nextX = currentPosition.x + horizontalSpeed * dt;

    if (nextX < roadLeftBound || nextX > roadRightBound) {
      _direction *= -1;
      _segmentProgress = 0;
    }

    return Vector2(
      baseSpeed * horizontalSpeedMultiplier * _direction,
      baseSpeed,
    );
  }

  @override
  void reset() {
    _direction = startDirection ?? 1;
    _segmentProgress = 0;
  }
}
