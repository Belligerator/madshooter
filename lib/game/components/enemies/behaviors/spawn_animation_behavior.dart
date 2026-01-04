import 'package:flame/components.dart';
import 'movement_behavior.dart';

/// Movement behavior that animates enemy from spawn point to target position
/// After reaching target, enemy continues with normal downward movement
class SpawnAnimationBehavior extends MovementBehavior {
  final Vector2 startPosition;
  final Vector2 targetPosition;
  final double duration;

  double _elapsed = 0;
  bool _completed = false;

  SpawnAnimationBehavior({
    required this.startPosition,
    required this.targetPosition,
    this.duration = 0.5, // Default 0.5 second animation
  });

  @override
  void initialize({
    required double screenWidth,
    required double screenHeight,
    required double roadLeftBound,
    required double roadRightBound,
    Vector2 Function()? getPlayerPosition,
  }) {
    // No initialization needed for spawn animation
  }

  @override
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed) {
    if (_completed) {
      // Animation finished, move down normally
      return Vector2(0, baseSpeed);
    }

    _elapsed += dt;

    if (_elapsed >= duration) {
      // Animation complete
      _completed = true;
      return Vector2(0, baseSpeed);
    }

    // Lerp from start to target
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final easedProgress = _easeOutCubic(progress);
    final targetPos = _lerpVector2(startPosition, targetPosition, easedProgress);

    // Calculate velocity to reach target
    final delta = targetPos - currentPosition;
    return delta / dt;
  }

  /// Linear interpolation between two Vector2s
  Vector2 _lerpVector2(Vector2 a, Vector2 b, double t) {
    return Vector2(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
    );
  }

  /// Ease out cubic for smooth deceleration
  double _easeOutCubic(double t) {
    final t1 = t - 1;
    return t1 * t1 * t1 + 1;
  }

  MovementBehavior copy() {
    return SpawnAnimationBehavior(
      startPosition: startPosition.clone(),
      targetPosition: targetPosition.clone(),
      duration: duration,
    );
  }
}
