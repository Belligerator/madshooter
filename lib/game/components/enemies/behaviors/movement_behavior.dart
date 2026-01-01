import 'package:flame/components.dart';

/// Base class for enemy movement behaviors using the Strategy Pattern.
/// Each behavior returns a velocity vector that the enemy should move at.
abstract class MovementBehavior {
  /// Screen bounds for constraining movement
  late double screenWidth;
  late double screenHeight;
  late double roadLeftBound;
  late double roadRightBound;

  /// Reference to game for player position (needed for tracking behaviors)
  Vector2 Function()? getPlayerPosition;

  /// Initialize the behavior with screen/road bounds
  void initialize({
    required double screenWidth,
    required double screenHeight,
    required double roadLeftBound,
    required double roadRightBound,
    Vector2 Function()? getPlayerPosition,
  }) {
    this.screenWidth = screenWidth;
    this.screenHeight = screenHeight;
    this.roadLeftBound = roadLeftBound;
    this.roadRightBound = roadRightBound;
    this.getPlayerPosition = getPlayerPosition;
  }

  /// Called each frame to get the velocity for this behavior.
  /// [currentPosition] - enemy's current position
  /// [dt] - delta time
  /// [baseSpeed] - the enemy's base downward speed
  /// Returns the velocity vector the enemy should move at
  Vector2 getVelocity(Vector2 currentPosition, double dt, double baseSpeed);

  /// Called when the behavior should reset (e.g., enemy respawns)
  void reset() {}

  /// Whether this behavior has completed its movement pattern
  bool get isComplete => false;
}
