import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';

class UpgradePoint extends CircleComponent with HasGameRef<ShootingGame>, CollisionCallbacks {
  static const double speed = 30.0;
  static const double pointRadius = 8.0;

  UpgradePoint({required Vector2 spawnPosition}) {
    position = spawnPosition;
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    radius = pointRadius;
    paint = Paint()..color = Colors.amber;
    priority = 60;

    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += speed * dt;

    if (position.y > gameRef.size.y + radius) {
      removeFromParent();
    }
  }

  void collect() {
    gameRef.addUpgradePoint();
    removeFromParent();
  }
}
