import 'package:flame/components.dart';
import '../shooting_game.dart';

class ExplosionEffect extends SpriteAnimationComponent with HasGameReference<ShootingGame> {
  final Vector2 origin;

  // Original sprite dimensions (from image files)
  final double _originalWidth = 256;
  final double _originalHeight = 256;

  // Base display size (adjust as needed for visual preference)
  final double _baseWidth = 80.0;
  double get _baseHeight => _baseWidth * (_originalHeight / _originalWidth);

  ExplosionEffect({required this.origin});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load all 11 explosion sprite frames in parallel
    final sprites = await Future.wait([
      game.loadSprite('effects/explosion/Explosion1.webp'),
      game.loadSprite('effects/explosion/Explosion2.webp'),
      game.loadSprite('effects/explosion/Explosion3.webp'),
      game.loadSprite('effects/explosion/Explosion4.webp'),
      game.loadSprite('effects/explosion/Explosion5.webp'),
      game.loadSprite('effects/explosion/Explosion6.webp'),
      game.loadSprite('effects/explosion/Explosion7.webp'),
      game.loadSprite('effects/explosion/Explosion8.webp'),
      game.loadSprite('effects/explosion/Explosion9.webp'),
      game.loadSprite('effects/explosion/Explosion10.webp'),
      game.loadSprite('effects/explosion/Explosion11.webp'),
    ]);

    // Create non-looping animation (plays once and stops)
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.05, loop: false);

    size = Vector2(_baseWidth, _baseHeight);
    anchor = Anchor.center;
    position = origin;

    // Render above enemies (priority 50) but below player (priority 200)
    priority = 100;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Remove when animation finishes
    if (animationTicker?.done() == true) {
      removeFromParent();
    }
  }
}
