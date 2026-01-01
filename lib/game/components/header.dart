import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

class Header extends Component with HasGameReference<ShootingGame> {
  static const double headerHeight = 80.0;

  late RectangleComponent background;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set high priority to render on top of everything
    priority = 1000;

    // Create header background - solid black
    background = RectangleComponent(
      size: Vector2(game.size.x, headerHeight),
      position: Vector2(0, 0),
      paint: Paint()..color = Colors.black,
    );
    add(background);
  }

  // Empty methods kept for compatibility (can be removed later)
  void updateKills(int kills) {}
  void updateHealth(int current, int max) {}
  void updateUpgradeLabels() {}
}
