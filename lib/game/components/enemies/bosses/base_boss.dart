import 'dart:ui';

import 'package:flame/components.dart';

import '../enemies/base_enemy.dart';
import '../behaviors/movement_behavior.dart';
import '../../shooting/shooting_pattern.dart';
import '../../shooting/patterns/single_shot_pattern.dart';
import '../../shooting/bullet_config.dart';
import '../../enemy_bullet.dart';
import 'boss_phase_config.dart';

/// Abstract base class for all boss enemies.
/// Provides phase system, shooting, position clamping, and minion spawning.
abstract class BaseBoss extends BaseEnemy {
  /// Current phase index (0-based)
  int currentPhaseIndex = 0;

  /// Shoot timer
  double _shootTimer = 0;

  /// Current fire interval (from phase config)
  double fireInterval = 2.0;

  /// Current shooting pattern (from phase config)
  ShootingPattern _shootingPattern = SingleShotPattern();

  /// Pending bullets from burst patterns (delay > 0)
  final List<_PendingBullet> _pendingBullets = [];

  BaseBoss({
    required super.maxHealth,
    required super.spritePath,
    required super.baseWidth,
    required super.baseHeight,
    required super.healthBarWidth,
    required super.healthBarX,
    required super.healthBarY,
    super.destroyedOnPlayerCollision = false,
    super.clampToScreenBounds = false,
    super.dropUpgradePoints = 5,
  });

  /// List of phase configurations, sorted by healthThreshold descending.
  /// First phase should have threshold 1.0 (full health).
  List<BossPhaseConfig> get phases;

  /// Override to provide custom position clamping bounds.
  /// Returns (minX, maxX, minY, maxY). Null values use defaults.
  /// Defaults to 50% visible on each side of screen. Enemy anchor is in ceter, so do not subtract half width/height.
  ({double? minX, double? maxX, double? minY, double? maxY}) get positionBounds => (
    minX: 0, // 50% visible on left
    maxX: game.gameWidth, // 50% visible on right
    minY: -size.y, // can go fully off-screen at top - good for spawning
    maxY: game.gameHeight * 0.70, // Cannot go below y=0.8
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Boses are bigger, set lower priority, so smaller enemies are seen
    priority = 30;

    // Initialize first phase
    _applyPhase(0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update current phase abilities (boss-specific, phase-based)
    if (currentPhaseIndex < phases.length) {
      for (final ability in phases[currentPhaseIndex].abilities) {
        ability.update(dt, this);
      }
    }

    // Clamp boss position
    _clampPosition();

    // Handle pending burst bullets
    _processPendingBullets(dt);

    // Handle shooting
    _shootTimer += dt;
    if (_shootTimer >= fireInterval) {
      _shoot();
      _shootTimer = 0;
    }

    // Check phase transitions
    _checkPhaseTransition();
  }

  void _clampPosition() {
    final bounds = positionBounds;

    final minX = bounds.minX ?? 0;
    final maxX = bounds.maxX ?? game.gameWidth;
    final minY = bounds.minY ?? -size.y;
    final maxY = bounds.maxY ?? game.gameHeight;

    position.x = position.x.clamp(minX, maxX);
    position.y = position.y.clamp(minY, maxY);
  }

  void _checkPhaseTransition() {
    if (phases.isEmpty) return;

    final healthPercent = currentHealth / maxHealth;

    // Find the appropriate phase for current health
    for (int i = currentPhaseIndex + 1; i < phases.length; i++) {
      final phase = phases[i];
      if (healthPercent <= phase.healthThreshold) {
        _transitionToPhase(i);
      }
    }
  }

  void _transitionToPhase(int phaseIndex) {
    if (phaseIndex < 0 || phaseIndex >= phases.length) return;
    if (phaseIndex == currentPhaseIndex) return;

    // Exit old phase abilities
    if (currentPhaseIndex < phases.length) {
      for (final ability in phases[currentPhaseIndex].abilities) {
        ability.onPhaseExit(this);
      }
    }

    currentPhaseIndex = phaseIndex;
    _applyPhase(phaseIndex);

    // Visual feedback: flash red
    _flashRed();
  }

  void _applyPhase(int phaseIndex) {
    final phase = phases[phaseIndex];

    // Apply movement behavior if specified
    if (phase.behavior != null) {
      _updateBehavior(phase.behavior!);
    }

    // Apply shooting pattern
    if (phase.shootingPattern != null) {
      _shootingPattern = phase.shootingPattern!;
    }

    // Apply fire interval
    fireInterval = phase.fireInterval;

    // Enter new phase abilities
    for (final ability in phase.abilities) {
      ability.onPhaseEnter(this);
    }

    // Call phase enter callback
    phase.onEnter?.call();
  }

  void _updateBehavior(MovementBehavior behavior) {
    behavior.initialize(
      screenWidth: game.gameWidth,
      screenHeight: game.gameHeight,
      roadLeftBound: 0,
      roadRightBound: game.gameWidth,
      getPlayerPosition: () => game.player.position,
    );
    movementBehavior = behavior;
  }

  /// Get the origin position for bullets.
  /// Default is bottom center of the sprite.
  Vector2 getBulletOrigin() {
    final offset = Vector2(0, baseHeight / 2);
    return position + (offset..rotate(angle));
  }

  void _shoot() {
    final bulletOrigin = getBulletOrigin();
    final bulletConfigs = _shootingPattern.getBullets(bulletOrigin, targetPosition: game.player.position);

    for (final config in bulletConfigs) {
      if (config.delay > 0) {
        // Queue delayed bullet
        _pendingBullets.add(_PendingBullet(config: config, origin: bulletOrigin.clone(), remainingDelay: config.delay));
      } else {
        // Fire immediately
        _spawnBullet(bulletOrigin, config);
      }
    }
  }

  void _processPendingBullets(double dt) {
    final toRemove = <_PendingBullet>[];

    for (final pending in _pendingBullets) {
      pending.remainingDelay -= dt;
      if (pending.remainingDelay <= 0) {
        _spawnBullet(pending.origin, pending.config);
        toRemove.add(pending);
      }
    }

    _pendingBullets.removeWhere(toRemove.contains);
  }

  void _spawnBullet(Vector2 origin, BulletConfig config) {
    final spawnPos = origin + config.offset;
    game.world.add(
      EnemyBullet(origin: spawnPos, directionAngle: config.angle, speedMultiplier: config.speedMultiplier),
    );
  }

  void _flashRed() {
    paint.colorFilter = const ColorFilter.mode(Color(0xFFFF0000), BlendMode.modulate);
    Future.delayed(const Duration(milliseconds: 200), () {
      paint.colorFilter = null;
    });
  }
}

/// Helper class for delayed bullet spawning
class _PendingBullet {
  final BulletConfig config;
  final Vector2 origin;
  double remainingDelay;

  _PendingBullet({required this.config, required this.origin, required this.remainingDelay});
}
