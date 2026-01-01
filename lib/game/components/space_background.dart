import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

/// Space background with parallax scrolling layers
class SpaceBackground extends ParallaxComponent<ShootingGame> {
  final int? initialLevelId;

  SpaceBackground({this.initialLevelId});

  @override
  Future<void> onLoad() async {
    priority = -100; // Render behind everything
    await _loadBackground(initialLevelId);
  }

  Future<void> updateBackground(int levelId) async {
    await _loadBackground(levelId);
  }

  Future<void> _loadBackground(int? levelId) async {
    List<String> paths = ['parallax/background.webp', 'parallax/foreground.webp'];

    if (levelId != null) {
      final levelBgPath = 'parallax/level_$levelId/background.webp';
      final levelFgPath = 'parallax/level_$levelId/foreground.webp';

      try {
        // Try to load the level specific images
        await game.images.load(levelBgPath);
        await game.images.load(levelFgPath);
        paths = [levelBgPath, levelFgPath];
        print('Loaded custom background for level $levelId');
      } catch (e) {
        // Fallback to default if level specific images are missing
        print('Custom background for level $levelId not found, using default.');
      }
    }

    parallax = await game.loadParallax(
      [
        ParallaxImageData(paths[0]),
        ParallaxImageData(paths[1]),
      ],
      baseVelocity: Vector2(0, -10),
      velocityMultiplierDelta: Vector2(0, 1.5),
      size: Vector2(game.gameWidth, game.gameHeight),
      fill: LayerFill.width,
      repeat: ImageRepeat.repeat,
    );
  }
}
