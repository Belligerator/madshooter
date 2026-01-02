import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../shooting_game.dart';

class UpgradePoint extends SpriteComponent with HasGameReference<ShootingGame>, CollisionCallbacks {
  static const double speed = 30.0;
  static const double displaySize = 24.0;
  static const double _originalWidth = 182.0;

  static double get displayScale => displaySize / _originalWidth;

  // Hitbox dimensions (relative to original sprite)
  static const double _hitboxRadius = 53.0;

  UpgradePoint({required Vector2 spawnPosition}) {
    position = spawnPosition;
    size = Vector2.all(displaySize);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    sprite = await game.loadSprite('pickups/PickUp_PowerUp.webp');
    priority = 60;

    add(
      CircleHitbox(
        radius: _hitboxRadius * displayScale,
        position: Vector2(size.x / 2, size.y / 2),
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += speed * dt;

    if (position.y > game.gameHeight + size.y) {
      removeFromParent();
    }
  }

  void collect() {
    game.addUpgradePoint();
    removeFromParent();
  }
}
