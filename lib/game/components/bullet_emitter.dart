import 'package:flame/components.dart';
import '../shooting_game.dart';

class BulletEmitter extends SpriteAnimationComponent with HasGameReference<ShootingGame> {
  final Vector2 origin;

  // Original sprite dimensions (from image file)
  final double _originalWidth = 256;
  final double _originalHeight = 256;

  // Base display size (scaled down for game)
  final double _baseWidth = 40.0;
  double get _baseHeight => _baseWidth * (_originalHeight / _originalWidth);

  BulletEmitter({required this.origin});

  @override
  Future<void> onLoad() async {
    super.onLoad();

  // debugMode = true;

    // Load the 4 emitter sprites
    final sprites = await Future.wait([
      game.loadSprite('bullet/Emitter_Player_Bullet1.webp'),
      game.loadSprite('bullet/Emitter_Player_Bullet2.webp'),
      game.loadSprite('bullet/Emitter_Player_Bullet3.webp'),
      game.loadSprite('bullet/Emitter_Player_Bullet4.webp'),
    ]);

    // Play once and stop
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.05, loop: false);

    size = Vector2(_baseWidth, _baseHeight);
    anchor = Anchor.bottomCenter;
    position = origin;

    // Render above player
    priority = 101;
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
