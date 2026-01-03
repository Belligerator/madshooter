import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:madshooter/game/components/enemies/behaviors/behavior_factory.dart';

import '../../behaviors/strategic_behavior.dart';
import '../../behaviors/track_player_behavior.dart';
import '../../../shooting/patterns/single_shot_pattern.dart';
import '../../../shooting/patterns/spread_pattern.dart';
import '../base_boss.dart';
import '../boss_phase_config.dart';

/// Tank Boss - First major boss (Level 5)
/// Heavy armored boss with 3 phases of increasing aggression.
class TankBoss extends BaseBoss {
  // Original sprite dimensions (from image file)
  static const double _originalWidth = 256.0;
  static const double _originalHeight = 256.0;

  // Base display size (what you work with in game)
  static const double _baseWidth = 200.0;
  static const double _baseHeight = _baseWidth * (_originalHeight / _originalWidth);

  // Scale factor from original to base size
  static double get displayScale => _baseWidth / _originalWidth;

  // Hitbox dimensions (relative to original sprite)
  static const double _hitboxWidth = 122.0;
  static const double _hitboxHeight = 130.0;

  // Scaled hitbox getters (for positioning from other components)
  static double get scaledHitboxWidth => _hitboxWidth * displayScale;
  static double get scaledHitboxHeight => _hitboxHeight * displayScale;

  TankBoss()
      : super(
          maxHealth: 2000,
          spritePath: 'enemies/Enemy_Tank_Base.webp',
          baseWidth: _baseWidth,
          baseHeight: _baseHeight,
          healthBarWidth: scaledHitboxWidth,
          healthBarX: _baseWidth / 2 - scaledHitboxWidth / 2,
          healthBarY: _baseHeight / 2 - scaledHitboxHeight / 2,
          dropUpgradePoints: 5,
        );

  @override
  List<BossPhaseConfig> get phases => [
    // Phase 1: Hover at top, single shots
    BossPhaseConfig(
      healthThreshold: 1.0,
      behavior: StrategicBehavior(
        strategy: StrategyType.hover,
        targetY: defaultTargetY,
        approachSpeed: 3.0,
      ),
      shootingPattern: SingleShotPattern(),
      fireInterval: 2.0,
    ),
    // Phase 2: Track player, faster shooting
    BossPhaseConfig(
      healthThreshold: 0.66,
      behavior: TrackPlayerBehavior(
        reactionSpeed: 0.1,
        maxHorizontalSpeedMultiplier: 5.0,
        targetY: 0.15,
      ),
      shootingPattern: SingleShotPattern(),
      fireInterval: 1.5,
    ),
    // Phase 3: Orbit, spread shots
    BossPhaseConfig(
      healthThreshold: 0.33,
      behavior: StrategicBehavior(
        strategy: StrategyType.orbit,
        orbitRadius: 50,
        orbitSpeed: 0.5,
        targetY: 0.2,
        continueOnComplete: false,
      ),
      shootingPattern: SpreadPattern(bulletCount: 3, spreadAngle: 30),
      fireInterval: 1.0,
    ),
  ];

  @override
  void addHitboxes() {
    add(
      CircleHitbox(
        radius: scaledHitboxWidth / 2,
        position: Vector2(_baseWidth / 2, _baseHeight / 2),
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ),
    );
  }
}
