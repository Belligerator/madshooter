import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:madshooter/game/components/enemies/hitbox_config.dart';

import '../behaviors/movement_behavior.dart';
import '../behaviors/behavior_factory.dart';
import '../../shooting/shooting_pattern.dart';
import '../../shooting/shooting_pattern_factory.dart';
import '../../shooting/patterns/aimed_pattern.dart';
import 'base_boss.dart';
import 'boss_phase_config.dart';
import 'abilities/boss_ability.dart';
import 'abilities/ability_factory.dart';

/// Data-driven mini-boss that can be fully configured via JSON.
/// Used for per-level mini-bosses with customizable phases.
class MiniBoss extends BaseBoss {
  final List<BossPhaseConfig> _phases;
  final HitboxConfig hitboxConfig;

  MiniBoss({
    required super.maxHealth,
    required super.spritePath,
    required super.baseWidth,
    required super.baseHeight,
    required List<BossPhaseConfig> phases,
    HitboxConfig? hitboxConfig,
    double? healthBarWidth,
    super.dropUpgradePoints = 3,
  })  : _phases = phases,
        hitboxConfig = hitboxConfig ?? HitboxConfig.defaultTank(baseWidth),
        super(
          healthBarWidth: healthBarWidth ?? baseWidth * 0.6,
          healthBarX: (baseWidth - (healthBarWidth ?? baseWidth * 0.6)) / 2,
          healthBarY: baseHeight * 0.1,
        );

  @override
  List<BossPhaseConfig> get phases => _phases;

  @override
  Vector2 getBulletOrigin() {
    // Use hitbox center offset if available, rotated by boss angle
    final offset = Vector2(hitboxConfig.offsetX, hitboxConfig.offsetY);
    return position + (offset..rotate(angle));
  }

  @override
  void addHitboxes() {
    final center = Vector2(
      baseWidth / 2 + hitboxConfig.offsetX,
      baseHeight / 2 + hitboxConfig.offsetY,
    );

    if (hitboxConfig.type == HitboxType.circle) {
      add(
        CircleHitbox(
          radius: hitboxConfig.width / 2,
          position: center,
          anchor: Anchor.center,
          collisionType: CollisionType.passive,
        ),
      );
    } else {
      add(
        RectangleHitbox(
          size: Vector2(hitboxConfig.width, hitboxConfig.height),
          position: center,
          anchor: Anchor.center,
          collisionType: CollisionType.passive,
        ),
      );
    }
  }
}

/// Factory for creating MiniBoss instances from JSON configuration.
class MiniBossFactory {
  /// Create a MiniBoss from a JSON event map.
  /// 
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "type": "spawn_mini_boss",
  ///   "sprite": "enemies/mini_tank.webp",
  ///   "health": 500,
  ///   "width": 100,
  ///   "height": 100,           // optional, defaults to width
  ///   "drop_up": 3,            // optional
  ///   
  ///   // Hitbox configuration (all optional with defaults for Enemy_Tank_Base.webp)
  ///   "hitbox": {
  ///     "type": "circle",           // "circle" or "rectangle"
  ///     "original_sprite_width": 256,
  ///     "original_hitbox_width": 122,
  ///     "original_hitbox_height": 130,
  ///     "original_offset_x": 0,
  ///     "original_offset_y": 0
  ///   },
  ///   
  ///   "phases": [...]
  /// }
  /// ```
  static MiniBoss fromJson(Map<String, dynamic> json) {
    final sprite = json['sprite'] as String? ?? 'enemies/Enemy_Tank_Base.webp';
    final health = json['health'] as int? ?? 500;
    final width = (json['width'] as num?)?.toDouble() ?? 100.0;
    final height = (json['height'] as num?)?.toDouble() ?? width;
    final dropUp = json['drop_up'] as int? ?? 3;

    // Parse hitbox configuration
    HitboxConfig? hitboxConfig;
    final hitboxJson = json['hitbox'] as Map<String, dynamic>?;
    if (hitboxJson != null) {
      final typeStr = hitboxJson['type'] as String? ?? 'circle';
      final type = typeStr == 'rectangle' ? HitboxType.rectangle : HitboxType.circle;
      
      // Original sprite dimensions (defaults for Enemy_Tank_Base.webp: 256x256)
      final originalSpriteWidth = (hitboxJson['original_sprite_width'] as num?)?.toDouble() ?? 256.0;
      
      // Original hitbox dimensions (defaults for Enemy_Tank_Base.webp: 122x130)
      final originalHitboxWidth = (hitboxJson['original_hitbox_width'] as num?)?.toDouble() ?? 122.0;
      final originalHitboxHeight = (hitboxJson['original_hitbox_height'] as num?)?.toDouble() ?? 130.0;
      
      // Center offset in original coordinates
      final originalOffsetX = (hitboxJson['original_offset_x'] as num?)?.toDouble() ?? 0.0;
      final originalOffsetY = (hitboxJson['original_offset_y'] as num?)?.toDouble() ?? 0.0;
      
      hitboxConfig = HitboxConfig.fromOriginal(
        originalSpriteWidth: originalSpriteWidth,
        originalHitboxWidth: originalHitboxWidth,
        originalHitboxHeight: originalHitboxHeight,
        originalOffsetX: originalOffsetX,
        originalOffsetY: originalOffsetY,
        displayWidth: width,
        type: type,
      );
    }
    // If no hitbox config provided, MiniBoss constructor will use defaultTank()

    // Parse phases
    final phasesJson = json['phases'] as List<dynamic>? ?? [];
    final phases = <BossPhaseConfig>[];

    for (final phaseJson in phasesJson) {
      final phaseMap = phaseJson as Map<String, dynamic>;
      phases.add(_parsePhase(phaseMap));
    }

    // If no phases defined, create a default single phase
    if (phases.isEmpty) {
      phases.add(BossPhaseConfig(
        healthThreshold: 1.0,
        shootingPattern: AimedPattern(),
        fireInterval: 2.0,
        behavior: BehaviorFactory.fromJson({
          'movement': 'strategic',
          'strategy': 'hover',
          'target_y': defaultTargetY,
        }),
      ));
    }

    // Sort phases by threshold descending (highest first)
    phases.sort((a, b) => b.healthThreshold.compareTo(a.healthThreshold));

    return MiniBoss(
      maxHealth: health,
      spritePath: sprite,
      baseWidth: width,
      baseHeight: height,
      hitboxConfig: hitboxConfig,
      dropUpgradePoints: dropUp,
      phases: phases,
    );
  }

  static BossPhaseConfig _parsePhase(Map<String, dynamic> json) {
    final threshold = (json['threshold'] as num?)?.toDouble() ?? 1.0;
    final fireInterval = (json['fire_interval'] as num?)?.toDouble() ?? 2.0;

    // Parse movement behavior
    MovementBehavior? behavior;
    if (json['movement'] != null) {
      behavior = BehaviorFactory.fromJson(json);
    } else {
      // Default behavior: Strategic Hover at y=0.1
      behavior = BehaviorFactory.fromJson({
        'movement': 'strategic',
        'strategy': 'hover',
        'target_y': defaultTargetY,
      });
    }

    // Parse shooting pattern
    ShootingPattern? shootingPattern;
    if (json['shooting'] != null) {
      shootingPattern = ShootingPatternFactory.fromJson(json);
    } else {
      shootingPattern = AimedPattern();
    }

    // Parse abilities
    final abilities = <BossAbility>[];
    if (json['abilities'] != null) {
      final abilitiesJson = json['abilities'] as List<dynamic>;
      for (final abilityJson in abilitiesJson) {
        abilities.add(AbilityFactory.fromJson(abilityJson as Map<String, dynamic>));
      }
    }

    return BossPhaseConfig(
      healthThreshold: threshold,
      behavior: behavior,
      shootingPattern: shootingPattern,
      fireInterval: fireInterval,
      abilities: abilities,
    );
  }
}
