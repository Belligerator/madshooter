import 'dart:math';

import 'package:flame/components.dart';
import 'package:madshooter/game/components/enemies/behaviors/behavior_factory.dart';

import 'movement_behavior.dart';

/// Random wandering movement behavior.
/// Enemy descends to a target Y position, then randomly picks points
/// within configurable boundaries and moves toward them at regular intervals.
class RandomWanderBehavior extends MovementBehavior {
  // Configuration parameters (normalized coordinates 0.0-1.0)
  final double targetY; // Y position to descend to before wandering
  final double interval; // Seconds between picking new random points
  final double minX; // Left boundary for random points (normalized)
  final double maxX; // Right boundary for random points (normalized)
  final double minY; // Top boundary for random points (normalized)
  final double maxY; // Bottom boundary for random points (normalized)

  // State tracking
  double _timeSinceLastPick = 0.0; // Elapsed time since last random point selection
  bool _atTargetY = false; // Whether enemy has reached targetY phase
  Vector2? _currentTarget; // Current random point target (in screen coordinates)
  final Random _random = Random(); // Random number generator

  static const double _arrivalThreshold = 5.0; // Pixels - distance to consider waypoint reached

  RandomWanderBehavior({
    this.targetY = defaultTargetY,
    this.interval = 3.0,
    this.minX = 0.0,
    this.maxX = 1.0,
    this.minY = 0.0,
   this.maxY = defaultTargetY,
  })  : assert(minX < maxX, 'minX must be < maxX'),
        assert(minY < maxY, 'minY must be < maxY'),
        assert(interval > 0, 'interval must be > 0');

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    // Guard against very small dt
    if (dt <= 0.0001) {
      return Vector2(0, baseSpeed);
    }

    final targetYScreen = targetY * screenHeight;

    // Phase 1: Descend to targetY if not there yet
    if (!_atTargetY) {
      if (currentPosition.y >= targetYScreen) {
        _atTargetY = true;
        // Don't initialize _currentTarget here - lazy init on first wander call
      } else {
        return Vector2(0, baseSpeed); // Straight down
      }
    }

    // Phase 2: Wander behavior
    _timeSinceLastPick += dt;

    // Generate new point if interval elapsed or target is null
    if (_currentTarget == null || _timeSinceLastPick >= interval) {
      _currentTarget = _generateRandomPoint();
      _timeSinceLastPick = 0.0;
    }

    // Calculate direction to current target
    final direction = _currentTarget! - currentPosition;
    final distance = direction.length;

    // Check if arrived at current point - pick new one immediately
    if (distance < _arrivalThreshold) {
      _currentTarget = _generateRandomPoint();
      _timeSinceLastPick = 0.0;
      // Get velocity to new target (prevent standing still)
      final newDirection = _currentTarget! - currentPosition;
      newDirection.normalize();
      return Vector2(newDirection.x * baseSpeed, newDirection.y * baseSpeed);
    }

    // Move toward target
    direction.normalize();
    var velocityX = direction.x * baseSpeed;
    var velocityY = direction.y * baseSpeed;

    // Clamp to road bounds (left/right)
    final nextX = currentPosition.x + velocityX * dt;
    if (nextX < roadLeftBound) {
      velocityX = (roadLeftBound - currentPosition.x) / dt;
    } else if (nextX > roadRightBound) {
      velocityX = (roadRightBound - currentPosition.x) / dt;
    }

    return Vector2(velocityX, velocityY);
  }

  /// Generate a random point within the configured boundaries
  Vector2 _generateRandomPoint() {
    // Convert normalized boundaries to screen coordinates
    final roadWidth = roadRightBound - roadLeftBound;
    final screenMinX = roadLeftBound + minX * roadWidth;
    final screenMaxX = roadLeftBound + maxX * roadWidth;
    final screenMinY = minY * screenHeight;
    final screenMaxY = maxY * screenHeight;

    // Generate random point within boundaries
    final randomX = screenMinX + _random.nextDouble() * (screenMaxX - screenMinX);
    final randomY = screenMinY + _random.nextDouble() * (screenMaxY - screenMinY);

    return Vector2(randomX, randomY);
  }

  @override
  void reset() {
    _timeSinceLastPick = 0.0;
    _atTargetY = false;
    _currentTarget = null;
  }

  MovementBehavior copy() {
    return RandomWanderBehavior(
      targetY: targetY,
      interval: interval,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }
}
