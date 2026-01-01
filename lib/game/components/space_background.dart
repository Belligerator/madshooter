import 'package:flame/components.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

/// Space background with parallax scrolling layers
class SpaceBackground extends ParallaxComponent<ShootingGame> {
  @override
  Future<void> onLoad() async {
    priority = -100; // Render behind everything
    
    parallax = await game.loadParallax(
      [
        ParallaxImageData('parallax/layer_1.webp'), // Slowest - deep background
        // ParallaxImageData('parallax/layer_2.webp'), // Medium speed
        ParallaxImageData('parallax/layer_3.webp'), // Fastest - foreground
      ],
      baseVelocity: Vector2(0, 10), // Base scroll speed
      velocityMultiplierDelta: Vector2(0, 1.5), // Each layer 1.2x faster
      size: Vector2(game.gameWidth, game.gameHeight),
      fill: LayerFill.width, // Fill width, tile vertically
      repeat: ImageRepeat.repeat,
    );
  }
}
