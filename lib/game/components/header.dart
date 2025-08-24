import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

class Header extends Component with HasGameRef<ShootingGame> {
  static const double headerHeight = 80.0;

  late RectangleComponent background;
  late TextComponent killsLabel;
  late TextComponent escapedLabel;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set high priority to render on top of everything
    priority = 1000;

    // Create header background
    background = RectangleComponent(
      size: Vector2(gameRef.size.x, headerHeight),
      position: Vector2(0, 0),
      paint: Paint()..color = Colors.black,
    );
    add(background);

    // Add kill counter label (in header)
    killsLabel = TextComponent(
      text: 'Kills: 0',
      position: Vector2(20, 25),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(killsLabel);

    // Add escaped soldiers counter (in header, to the right of kills)
    escapedLabel = TextComponent(
      text: 'Escaped: 0',
      position: Vector2(150, 25),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.red,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(escapedLabel);
  }

  // Update the kill count display
  void updateKills(int kills) {
    killsLabel.text = 'Kills: $kills';
  }

  // Update the escaped count display
  void updateEscaped(int escaped) {
    escapedLabel.text = 'Escaped: $escaped';
  }
}