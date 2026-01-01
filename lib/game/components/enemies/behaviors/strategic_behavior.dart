import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Strategy types for strategic movement
enum StrategyType {
  /// Hover at a fixed Y position
  hover,

  /// Move to flank the player (opposite side)
  flank,

  /// Circle around a point
  orbit,
}

/// Tier 3: Adaptive boss-like behavior with strategic positioning.
class StrategicBehavior extends MovementBehavior {
  /// The strategy to use
  final StrategyType strategy;

  /// Target Y position in normalized coordinates (0-1)
  final double targetY;

  /// How quickly to reach target position
  final double approachSpeed;

  /// For orbit: radius of the orbit
  final double orbitRadius;

  /// For orbit: angular speed (radians per second)
  final double orbitSpeed;

  /// Reaction time for flank behavior (seconds)
  final double reactionTime;

  /// Whether to continue normal movement after reaching target Y
  final bool continueOnComplete;

  /// Whether we've reached the target Y
  bool _atTargetY = false;

  /// Elapsed time for orbit calculation
  double _elapsedTime = 0;

  /// Timer for reaction
  double _timeSinceLastReaction = 0;

  /// Current target X for flank
  double? _targetFlankX;

  /// Center X for orbit
  double? _orbitCenterX;

  /// Center Y for orbit (dynamic, moves down)
  double? _orbitCenterY;

  StrategicBehavior({
    this.strategy = StrategyType.hover,
    this.targetY = 0.2,
    this.approachSpeed = 1,
    this.continueOnComplete = true,
    this.orbitRadius = 50.0,
    this.orbitSpeed = 1.0,
    this.reactionTime = 1,
  });

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    _elapsedTime += dt;

    final targetYScreen = targetY * screenHeight;

    // First, descend to target Y if not there yet
    if (!_atTargetY) {
      if (currentPosition.y >= targetYScreen) {
        _atTargetY = true;
        _orbitCenterX = currentPosition.x;
        _orbitCenterY = targetYScreen;
      } else {
        // Move down towards target Y
        return Vector2(0, baseSpeed * approachSpeed);
      }
    }

    // Once at target Y, apply strategy
    switch (strategy) {
      case StrategyType.hover:
        return _hoverBehavior(currentPosition, dt, baseSpeed);
      case StrategyType.flank:
        return _flankBehavior(currentPosition, dt, baseSpeed);
      case StrategyType.orbit:
        return _orbitBehavior(currentPosition, dt, baseSpeed);
    }
  }

  Vector2 _hoverBehavior(Vector2 currentPosition, double dt, double baseSpeed) {
    // Stay at current position, slight oscillation
    final targetYScreen = targetY * screenHeight;
    final dy = targetYScreen - currentPosition.y;

    return Vector2(0, dy * 2); // Gentle correction to stay at Y
  }

  Vector2 _flankBehavior(Vector2 currentPosition, double dt, double baseSpeed) {
    double horizontalVelocity = 0;
    
    _timeSinceLastReaction += dt;

    if (getPlayerPosition != null) {
      // Initialize target if null
      if (_targetFlankX == null) {
         _updateFlankTarget();
      }
      
      // Update target only after reaction time
      if (_timeSinceLastReaction >= reactionTime) {
        _updateFlankTarget();
        _timeSinceLastReaction = 0;
      }

      // Move towards the stored target
      if (_targetFlankX != null) {
          final dx = _targetFlankX! - currentPosition.x;
          horizontalVelocity = dx.clamp(-baseSpeed * 1.5, baseSpeed * 1.5);
      }
    }

    // Maintain Y position or drift down
    final verticalDrift = continueOnComplete ? baseSpeed : 0.0;
    
    if (continueOnComplete) {
       return Vector2(horizontalVelocity, verticalDrift);
    }

    final targetYScreen = targetY * screenHeight;
    final dy = (targetYScreen - currentPosition.y) * 2;

    return Vector2(horizontalVelocity, dy);
  }

  void _updateFlankTarget() {
      final playerPos = getPlayerPosition!();
      final roadCenter = (roadLeftBound + roadRightBound) / 2;

      // Target the opposite side of the road from the player
      if (playerPos.x < roadCenter) {
        _targetFlankX = roadRightBound - 20; // Go right
      } else {
        _targetFlankX = roadLeftBound + 20; // Go left
      }
  }

  Vector2 _orbitBehavior(Vector2 currentPosition, double dt, double baseSpeed) {
    final baseSpeedTemp = continueOnComplete ? baseSpeed : 0.0;
   
    _orbitCenterX ??= (roadLeftBound + roadRightBound) / 2;
    _orbitCenterY ??= targetY * screenHeight;
    
    // Move the orbit center down
    _orbitCenterY = _orbitCenterY! + baseSpeedTemp * dt;

    // Calculate proper circular motion velocity (tangent to circle)
    // For x = cx + r*cos(θ), y = cy + r*sin(θ)
    // Velocity: vx = -r*ω*sin(θ), vy = r*ω*cos(θ)
    final angle = _elapsedTime * orbitSpeed;
    final vx = -orbitRadius * orbitSpeed * _sin(angle);
    final vy = orbitRadius * orbitSpeed * _cos(angle);

    // Also add correction to stay on the circle (prevents drift)
    final orbitTargetX = _orbitCenterX! + orbitRadius * _cos(angle);
    final orbitTargetY = _orbitCenterY! + orbitRadius * _sin(angle);
    final correctionX = (orbitTargetX - currentPosition.x);
    final correctionY = (orbitTargetY - currentPosition.y);

    // Return rotational velocity + correction + center movement
    return Vector2(vx + correctionX, vy + correctionY + baseSpeedTemp);
  }

  // Simple trig without importing dart:math
  double _sin(double x) {
    // Taylor series approximation
    x = x % (2 * 3.14159265359);
    double result = x;
    double term = x;
    for (int i = 1; i <= 7; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  double _cos(double x) {
    return _sin(x + 3.14159265359 / 2);
  }

  @override
  void reset() {
    _atTargetY = false;
    _elapsedTime = 0;
    _timeSinceLastReaction = 0;
    _targetFlankX = null;
    _orbitCenterX = null;
    _orbitCenterY = null;
  }
}
