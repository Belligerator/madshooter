import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:madshooter/widgets/up_meter.dart';
import '../shooting_game.dart';
import 'bullet.dart';
import 'bullet_emitter.dart';
import 'thruster_effect.dart';
import 'upgrade_point.dart';
import 'enemies/base_enemy.dart';

class Player extends SpriteComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double speed = 200.0;
  static const double playerBottomPositionY = 100.0;

  // Original sprite dimensions (from image file)
  static const double _originalWidth = 256;
  static const double _originalHeight = 256;

  // Base display size (scaled down for game)
  final double baseWidth = 80.0;
  double get baseHeight => baseWidth * (_originalHeight / _originalWidth);

  // Main hitbox dimensions (in original sprite coordinates)
  final double hitboxWidth = 145;
  final double hitboxHeight = 160;
  final double hitboxOffsetX = 55;
  final double hitboxOffsetY = 60;

  // Nose hitbox dimensions (in original sprite coordinates)
  final double noseHitboxRadius = 20.0; // actual value
  final double noseHitboxOffsetX = _originalWidth / 2;
  final double noseHitboxOffsetY = 56.0; // actual value (center Y)

  // Thruster positions (in original sprite coordinates)
  final double thrusterLeftX = 70; // actual position
  final double thrusterRightX = 185; // actual position
  double get thrusterY => 220; // actual position (bottom of ship)

  // Scale factor from original to base size
  double get displayScale => baseWidth / _originalWidth;

  // Calculated hitbox size and position
  Vector2 get hitboxSize => Vector2(hitboxWidth * displayScale, hitboxHeight * displayScale);
  Vector2 get hitboxPosition => Vector2(hitboxOffsetX * displayScale, hitboxOffsetY * displayScale);

  // Calculated nose hitbox radius and position (for CircleHitbox)
  double get noseHitboxScaledRadius => noseHitboxRadius * displayScale;
  Vector2 get noseHitboxPosition => Vector2(noseHitboxOffsetX * displayScale, noseHitboxOffsetY * displayScale);

  late double leftBoundary = baseWidth / 2;
  late double rightBoundary = game.gameWidth - baseWidth / 2;
  late double topBoundary = baseHeight / 2;
  late double bottomBoundary = game.gameHeight - baseHeight / 2;

  double _timeSinceLastShot = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // debugMode = true;
    // Load player ship sprite
    sprite = await game.loadSprite('player/PlayerShip_Medium.webp');
    size = Vector2(baseWidth, baseHeight);
    anchor = Anchor.center;

    // Set priority to render above enemies but below header
    priority = 200;

    // Add main body hitbox
    add(RectangleHitbox(size: hitboxSize, position: hitboxPosition));

    // Add nose hitbox (circle)
    add(CircleHitbox(radius: noseHitboxScaledRadius, position: noseHitboxPosition, anchor: Anchor.center));

    // Add left thruster
    final leftThruster = ThrusterEffect();
    leftThruster.position = Vector2(thrusterLeftX * displayScale, thrusterY * displayScale);
    add(leftThruster);

    // Add right thruster
    final rightThruster = ThrusterEffect();
    rightThruster.position = Vector2(thrusterRightX * displayScale, thrusterY * displayScale);
    add(rightThruster);

    // Position at bottom center of game world
    position = Vector2(game.gameWidth / 2, game.gameHeight - playerBottomPositionY);
  }

  void move(double joystickX, double joystickY) {
    // Direct proportional movement based on joystick input
    position.x += joystickX * 2;
    position.y += joystickY * 2;

    // Clamp to screen boundaries
    position.x = position.x.clamp(leftBoundary, rightBoundary);
    position.y = position.y.clamp(topBoundary, bottomBoundary);
  }

  void moveByDelta(double deltaX, double deltaY) {
    // Move player by the same amount as thumb (1:1 relative movement)
    position.x += deltaX;
    position.y += deltaY;
    position.x = position.x.clamp(leftBoundary - baseWidth / 2, rightBoundary + baseWidth / 2);
    position.y = position.y.clamp(topBoundary, bottomBoundary - upMeterHeight);
  }

  // Joystick-style constant speed movement
  static const double baseSpeed = 200.0; // pixels per second
  double speedMultiplier = 1.0; // can be upgraded later

  @override
  void update(double dt) {
    super.update(dt);

    // Handle automatic shooting with upgraded fire rate
    _timeSinceLastShot += dt;

    final currentFireInterval = game.getFireInterval(); // Get seconds between shots

    if (_timeSinceLastShot >= currentFireInterval) {
      _shoot();
      _timeSinceLastShot = 0;
    }
  }

  void _shoot() {
    // Player hitbox top in world coordinates
    final playerHitboxTopY = position.y - baseHeight / 2 + hitboxPosition.y;

    // Bullet origin so bullet hitbox bottom touches player hitbox top
    final bulletOriginPoint = Vector2(
      position.x,
      playerHitboxTopY - Bullet.scaledHitboxOffsetY - Bullet.scaledHitboxHeight,
    );

    // Emitter at player hitbox top
    final emitterOriginPoint = Vector2(position.x, playerHitboxTopY);

    // Create bullet
    final bullet = Bullet(origin: bulletOriginPoint);
    game.world.add(bullet);

    // Create muzzle flash effect
    final emitter = BulletEmitter(origin: emitterOriginPoint);
    game.world.add(emitter);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is UpgradePoint) {
      other.collect();
    }

    // Handle enemy collision
    if (other is BaseEnemy) {
      other.onPlayerCollision();
    }
  }
}
