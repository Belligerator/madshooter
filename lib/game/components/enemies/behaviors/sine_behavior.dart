import 'dart:math';

import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 1: Oscillates left-right in a sine wave while descending.
class SineBehavior extends MovementBehavior {
  /// Amplitude of the sine wave (pixels from center)
  final double amplitude;

  /// Frequency of oscillation (cycles per second)
  final double frequency;

  /// Tracks elapsed time for sine calculation
  double _elapsedTime = 0;

  /// Starting X position (captured on first update)
  double? _startX;

  SineBehavior({
    this.amplitude = 40.0,
    this.frequency = 0.5,
  });

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    // Capture starting X on first call
    _startX ??= currentPosition.x;

    // Guard against zero/tiny dt
    if (dt <= 0.0001) {
      return Vector2(0, baseSpeed);
    }

    _elapsedTime += dt;

    // Calculate target X position using sine wave
    final targetX = _startX! + amplitude * sin(2 * pi * frequency * _elapsedTime);

    // Calculate horizontal velocity to reach target
    final dx = targetX - currentPosition.x;
    final horizontalSpeed = dx / dt;

    // Clamp to road bounds
    final clampedHorizontalSpeed = _clampToRoad(
      currentPosition.x,
      horizontalSpeed,
      dt,
    );

    return Vector2(clampedHorizontalSpeed, baseSpeed);
  }

  double _clampToRoad(double currentX, double horizontalSpeed, double dt) {
    final nextX = currentX + horizontalSpeed * dt;

    if (nextX < roadLeftBound) {
      return (roadLeftBound - currentX) / dt;
    }
    if (nextX > roadRightBound) {
      return (roadRightBound - currentX) / dt;
    }

    return horizontalSpeed;
  }

  @override
  void reset() {
    _elapsedTime = 0;
    _startX = null;
  }
}
