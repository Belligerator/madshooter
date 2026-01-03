/// Hitbox shape type
enum HitboxType { circle, rectangle }

/// Hitbox configuration for MiniBoss
class HitboxConfig {
  final HitboxType type;
  final double width;
  final double height;
  final double offsetX; // Offset from sprite center
  final double offsetY; // Offset from sprite center

  const HitboxConfig({
    this.type = HitboxType.circle,
    required this.width,
    double? height,
    this.offsetX = 0,
    this.offsetY = 0,
  }) : height = height ?? width;

  /// Create hitbox config from original sprite dimensions
  /// [originalSpriteWidth] - Original image width
  /// [originalHitboxWidth] - Hitbox width in original image coordinates
  /// [originalHitboxHeight] - Hitbox height in original image coordinates
  /// [displayWidth] - Target display width
  factory HitboxConfig.fromOriginal({
    required double originalSpriteWidth,
    required double originalHitboxWidth,
    double? originalHitboxHeight,
    double originalOffsetX = 0,
    double originalOffsetY = 0,
    required double displayWidth,
    HitboxType type = HitboxType.circle,
  }) {
    final scale = displayWidth / originalSpriteWidth;
    return HitboxConfig(
      type: type,
      width: originalHitboxWidth * scale,
      height: (originalHitboxHeight ?? originalHitboxWidth) * scale,
      offsetX: originalOffsetX * scale,
      offsetY: originalOffsetY * scale,
    );
  }

  /// Default hitbox for Enemy_Tank_Base.webp
  /// Original: 256x256 sprite, 122x130 hitbox, centered
  factory HitboxConfig.defaultTank(double displayWidth) {
    return HitboxConfig.fromOriginal(
      originalSpriteWidth: 256.0,
      originalHitboxWidth: 122.0,
      originalHitboxHeight: 130.0,
      displayWidth: displayWidth,
      type: HitboxType.circle,
    );
  }
}
