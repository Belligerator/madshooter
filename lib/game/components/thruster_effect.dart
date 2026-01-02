import 'package:flame/components.dart';
import '../shooting_game.dart';

class ThrusterEffect extends SpriteAnimationComponent
    with HasGameReference<ShootingGame> {

  // Original sprite dimensions (from image file)
  final double _originalWidth = 188;
  final double _originalHeight = 319;

  // Base display size
  final double _baseWidth = 20.0;  // Small thruster size
  double get _baseHeight => _baseWidth * (_originalHeight / _originalWidth);

  ThrusterEffect();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Load the 6 thruster sprites
    final sprites = await Future.wait([
      game.loadSprite('player/thruster_emit/Thruster_Player1.webp'),
      game.loadSprite('player/thruster_emit/Thruster_Player2.webp'),
      game.loadSprite('player/thruster_emit/Thruster_Player3.webp'),
      game.loadSprite('player/thruster_emit/Thruster_Player4.webp'),
      game.loadSprite('player/thruster_emit/Thruster_Player5.webp'),
      game.loadSprite('player/thruster_emit/Thruster_Player6.webp'),
    ]);

    // Loop continuously
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.08, loop: true);

    size = Vector2(_baseWidth, _baseHeight);
    anchor = Anchor.topCenter;

    // Render below player
    priority = 99;
  }
}
