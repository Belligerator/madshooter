import 'package:flame/components.dart';
import 'bullet_config.dart';

/// Base class for shooting patterns using Strategy Pattern.
/// Each pattern returns a list of bullet configurations to spawn.
abstract class ShootingPattern {
  /// Get bullet configurations for this pattern.
  /// [origin] - shooter's world position
  /// [targetPosition] - optional target (e.g., player position for aimed shots)
  List<BulletConfig> getBullets(Vector2 origin, {Vector2? targetPosition});

  /// Reset pattern state (e.g., for burst patterns tracking fired count)
  void reset() {}
}
