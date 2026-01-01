import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 2: Follows a smooth bezier curve path.
/// Uses normalized coordinates (0-1) for screen-size independence.
class BezierBehavior extends MovementBehavior {
  /// Control points in normalized coordinates (0-1)
  /// Minimum 2 points (start, end), can have 3-4 for cubic bezier
  final List<List<double>> controlPoints;

  /// Duration to complete the path in seconds
  final double duration;

  /// Progress along the path (0-1)
  double _progress = 0;

  /// Previous position for velocity calculation
  Vector2? _previousPosition;

  /// Whether the path is complete
  bool _isComplete = false;

  BezierBehavior({
    required this.controlPoints,
    this.duration = 4.0,
  }) : assert(controlPoints.length >= 2 && controlPoints.length <= 4);

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    if (_isComplete) {
      return Vector2(0, baseSpeed); // Fall straight down after completion
    }

    // Guard against zero/tiny dt
    if (dt <= 0.0001) {
      return Vector2(0, baseSpeed);
    }

    // Increment progress
    _progress += dt / duration;

    if (_progress >= 1.0) {
      _progress = 1.0;
      _isComplete = true;
    }

    // Calculate target position on bezier curve
    final targetNormalized = _evaluateBezier(_progress);

    // Convert normalized to screen coordinates
    final targetX = roadLeftBound + targetNormalized.x * (roadRightBound - roadLeftBound);
    final targetY = targetNormalized.y * screenHeight;

    final targetPosition = Vector2(targetX, targetY);

    // Calculate velocity to reach target
    _previousPosition ??= currentPosition.clone();

    final velocity = (targetPosition - currentPosition) / dt;

    _previousPosition = currentPosition.clone();

    return Vector2(velocity.x, baseSpeed);
    // return velocity;
  }

  Vector2 _evaluateBezier(double t) {
    final n = controlPoints.length - 1;

    if (n == 1) {
      // Linear
      return _lerp(
        Vector2(controlPoints[0][0], controlPoints[0][1]),
        Vector2(controlPoints[1][0], controlPoints[1][1]),
        t,
      );
    } else if (n == 2) {
      // Quadratic
      return _quadraticBezier(t);
    } else {
      // Cubic
      return _cubicBezier(t);
    }
  }

  Vector2 _lerp(Vector2 a, Vector2 b, double t) {
    return Vector2(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
    );
  }

  Vector2 _quadraticBezier(double t) {
    final p0 = Vector2(controlPoints[0][0], controlPoints[0][1]);
    final p1 = Vector2(controlPoints[1][0], controlPoints[1][1]);
    final p2 = Vector2(controlPoints[2][0], controlPoints[2][1]);

    final oneMinusT = 1 - t;
    return Vector2(
      oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * p1.x + t * t * p2.x,
      oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * p1.y + t * t * p2.y,
    );
  }

  Vector2 _cubicBezier(double t) {
    final p0 = Vector2(controlPoints[0][0], controlPoints[0][1]);
    final p1 = Vector2(controlPoints[1][0], controlPoints[1][1]);
    final p2 = Vector2(controlPoints[2][0], controlPoints[2][1]);
    final p3 = Vector2(controlPoints[3][0], controlPoints[3][1]);

    final oneMinusT = 1 - t;
    final oneMinusT2 = oneMinusT * oneMinusT;
    final oneMinusT3 = oneMinusT2 * oneMinusT;
    final t2 = t * t;
    final t3 = t2 * t;

    return Vector2(
      oneMinusT3 * p0.x + 3 * oneMinusT2 * t * p1.x + 3 * oneMinusT * t2 * p2.x + t3 * p3.x,
      oneMinusT3 * p0.y + 3 * oneMinusT2 * t * p1.y + 3 * oneMinusT * t2 * p2.y + t3 * p3.y,
    );
  }

  @override
  bool get isComplete => _isComplete;

//TODO: do i need it?
  // @override
  // bool get removeOnComplete => true;

  @override
  void reset() {
    _progress = 0;
    _previousPosition = null;
    _isComplete = false;
  }
}
