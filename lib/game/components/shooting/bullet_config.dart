import 'package:flame/components.dart';

/// Configuration for a single bullet spawn
class BulletConfig {
  /// Offset from the shooter's position (local coordinates)
  final Vector2 offset;
  
  /// Angle in radians (0 = down, positive = clockwise)
  final double angle;
  
  /// Speed multiplier (1.0 = default bullet speed)
  final double speedMultiplier;
  
  /// Delay before this bullet fires (for burst patterns)
  final double delay;

  BulletConfig({
    Vector2? offset,
    this.angle = 0.0,
    this.speedMultiplier = 1.0,
    this.delay = 0.0,
  }) : offset = offset ?? Vector2.zero();

  /// Create a copy with modified values
  BulletConfig copyWith({
    Vector2? offset,
    double? angle,
    double? speedMultiplier,
    double? delay,
  }) {
    return BulletConfig(
      offset: offset ?? this.offset,
      angle: angle ?? this.angle,
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      delay: delay ?? this.delay,
    );
  }
}
