import 'package:flame/components.dart';

import 'movement_behavior.dart';

/// Tier 2: Follows a path of connected quadratic bezier curves.
/// Uses normalized coordinates (0-1) for screen-size independence.
/// Allows values outside 0-1 for wider sweeping curves.
class ChainedBezierBehavior extends MovementBehavior {
  /// Points defining the chained bezier path.
  /// Explicit mode: [P0, C1, P1, C2, P2, ...] where P = anchor, C = control
  /// Smooth mode: [P0, P1, P2, ...] anchors only, controls auto-generated
  final List<List<double>> points;

  /// Duration to complete the entire path in seconds
  final double duration;

  /// Whether to auto-calculate control points for smooth curves
  final bool smooth;

  /// Smoothing tension (0 = tight curves, 1 = loose curves)
  final double tension;

  /// Progress along the entire path (0-1)
  double _progress = 0;

  /// Whether the path is complete
  bool _isComplete = false;

  /// Parsed control points (Vector2 format)
  late List<Vector2> _controlPoints;

  /// Number of segments in the chain
  late int _segmentCount;

  ChainedBezierBehavior({
    required this.points,
    this.duration = 4.0,
    this.smooth = false,
    this.tension = 0.5,
  }) : assert(points.length >= 3) {
    _parsePoints();
  }

  void _parsePoints() {
    if (smooth) {
      _controlPoints = _generateSmoothPath();
    } else {
      _controlPoints = points.map((p) => Vector2(p[0], p[1])).toList();
    }
    // Each segment needs 3 points, segments share endpoints
    // So: 3 points = 1 segment, 5 points = 2 segments, 7 points = 3 segments
    // Formula: segmentCount = (points.length - 1) / 2
    _segmentCount = (_controlPoints.length - 1) ~/ 2;
  }

  /// Generate smooth path from anchor points by calculating control points
  List<Vector2> _generateSmoothPath() {
    final anchors = points.map((p) => Vector2(p[0], p[1])).toList();

    if (anchors.length < 2) return anchors;

    if (anchors.length == 2) {
      // Just 2 points: create single segment with midpoint as control
      final mid = (anchors[0] + anchors[1]) / 2;
      return [anchors[0], mid, anchors[1]];
    }

    final result = <Vector2>[anchors[0]];

    for (int i = 0; i < anchors.length - 1; i++) {
      final prev = i > 0 ? anchors[i - 1] : anchors[0];
      final curr = anchors[i];
      final next = anchors[i + 1];

      // Calculate control point based on tangent direction
      final tangentIn = (curr - prev).normalized();
      final tangentOut = (next - curr).normalized();

      // Average tangent for smooth transition
      final tangent = (tangentIn + tangentOut).normalized();

      // Control point positioned along tangent, scaled by tension
      final segmentLength = (next - curr).length;
      final control = curr + tangent * segmentLength * tension * 0.5;

      result.add(control);
      result.add(next);
    }

    return result;
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

    // Calculate target position on chained bezier path
    final targetNormalized = _evaluateChainedBezier(_progress);

    // Convert normalized to screen coordinates
    final targetX =
        roadLeftBound + targetNormalized.x * (roadRightBound - roadLeftBound);
    final targetY = targetNormalized.y * screenHeight;

    final targetPosition = Vector2(targetX, targetY);

    // Calculate velocity to reach target
    final velocity = (targetPosition - currentPosition) / dt;

    // X from bezier, Y constant (same pattern as BezierBehavior)
    return Vector2(velocity.x, baseSpeed);
  }

  /// Evaluate the chained bezier at global progress t (0-1)
  Vector2 _evaluateChainedBezier(double t) {
    if (_segmentCount == 0) {
      return _controlPoints.first;
    }

    // Clamp t to valid range
    t = t.clamp(0.0, 1.0);

    // Determine which segment we're in
    final segmentProgress = t * _segmentCount;
    final segmentIndex = segmentProgress.floor().clamp(0, _segmentCount - 1);
    final localT = segmentProgress - segmentIndex;

    // Get the 3 control points for this segment
    final baseIndex = segmentIndex * 2;
    final p0 = _controlPoints[baseIndex];
    final p1 = _controlPoints[baseIndex + 1];
    final p2 = _controlPoints[baseIndex + 2];

    return _quadraticBezier(p0, p1, p2, localT);
  }

  /// Standard quadratic bezier evaluation
  Vector2 _quadraticBezier(Vector2 p0, Vector2 p1, Vector2 p2, double t) {
    final oneMinusT = 1 - t;
    return Vector2(
      oneMinusT * oneMinusT * p0.x + 2 * oneMinusT * t * p1.x + t * t * p2.x,
      oneMinusT * oneMinusT * p0.y + 2 * oneMinusT * t * p1.y + t * t * p2.y,
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
