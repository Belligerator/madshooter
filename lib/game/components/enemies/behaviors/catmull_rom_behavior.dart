import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 2: Follows a smooth Catmull-Rom spline through waypoints.
/// The curve passes through all waypoints with smooth transitions.
/// Uses normalized coordinates (0-1) for screen-size independence.
class CatmullRomBehavior extends MovementBehavior {
  /// Waypoints the curve passes through (in normalized 0-1 coordinates)
  final List<List<double>> waypoints;

  /// Duration to complete the entire path in seconds
  final double duration;

  /// Tension parameter (0.0 = tight curves, 1.0 = loose curves)
  /// Default 0.5 for standard Catmull-Rom
  final double tension;

  /// Progress along the entire path (0-1)
  double _progress = 0;

  /// Whether the path is complete
  bool _isComplete = false;

  /// Parsed waypoints as Vector2
  late List<Vector2> _points;

  /// Number of segments (waypoints - 1)
  late int _segmentCount;

  CatmullRomBehavior({
    required this.waypoints,
    this.duration = 4.0,
    this.tension = 0.5,
  }) : assert(waypoints.length >= 2) {
    _points = waypoints.map((p) => Vector2(p[0], p[1])).toList();
    _segmentCount = _points.length - 1;
  }

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

    // Calculate target position on Catmull-Rom spline
    final targetNormalized = _evaluateSpline(_progress);

    // Convert normalized to screen coordinates
    final targetX =
        roadLeftBound + targetNormalized.x * (roadRightBound - roadLeftBound);
    final targetY = targetNormalized.y * screenHeight;

    final targetPosition = Vector2(targetX, targetY);

    // Calculate velocity to reach target
    final velocity = (targetPosition - currentPosition) / dt;

    // X from spline, Y constant (same pattern as other behaviors)
    return Vector2(velocity.x, baseSpeed);
  }

  /// Evaluate the Catmull-Rom spline at global progress t (0-1)
  Vector2 _evaluateSpline(double t) {
    if (_segmentCount == 0) {
      return _points.first;
    }

    // Clamp t to valid range
    t = t.clamp(0.0, 1.0);

    // Determine which segment we're in
    final segmentProgress = t * _segmentCount;
    final segmentIndex = segmentProgress.floor().clamp(0, _segmentCount - 1);
    final localT = segmentProgress - segmentIndex;

    // Get the 4 control points for Catmull-Rom
    // For endpoints, we duplicate the first/last point
    final p0 = segmentIndex > 0 ? _points[segmentIndex - 1] : _points[0];
    final p1 = _points[segmentIndex];
    final p2 = _points[segmentIndex + 1];
    final p3 = segmentIndex < _segmentCount - 1
        ? _points[segmentIndex + 2]
        : _points[_segmentCount];

    return _catmullRom(p0, p1, p2, p3, localT);
  }

  /// Standard Catmull-Rom spline interpolation with tension
  Vector2 _catmullRom(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    // Tension factor (0.5 = standard Catmull-Rom)
    final s = (1 - tension) / 2;

    return Vector2(
      s * ((2 * p1.x) +
          (-p0.x + p2.x) * t +
          (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
          (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
      s * ((2 * p1.y) +
          (-p0.y + p2.y) * t +
          (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
          (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
    );
  }

  @override
  bool get isComplete => _isComplete;

  @override
  void reset() {
    _progress = 0;
    _isComplete = false;
  }
}
