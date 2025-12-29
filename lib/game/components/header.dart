import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../shooting_game.dart';

class Header extends Component with HasGameRef<ShootingGame> {
  static const double headerHeight = 80.0;

  late RectangleComponent background;
  late TextComponent killsLabel;
  final List<TextComponent> _healthHearts = [];

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Set high priority to render on top of everything
    priority = 1000;

    // Create header background - solid black without opacity
    background = RectangleComponent(
      size: Vector2(gameRef.size.x, headerHeight),
      position: Vector2(0, 0),
      paint: Paint()..color = Colors.black,
    );
    add(background);

    // Add kill counter label (in header)
    killsLabel = TextComponent(
      text: 'Kills: 0',
      position: Vector2(20, 15),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(killsLabel);

    // Add health hearts (in header, to the right of kills)
    _createHealthHearts();
  }

  void _createHealthHearts() {
    // Create 3 heart positions (where damage label was)
    for (int i = 0; i < 3; i++) {
      final heart = TextComponent(
        text: '❤',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 24,
            color: Colors.red,
          ),
        ),
        position: Vector2(150 + (i * 30), 15),
      );
      _healthHearts.add(heart);
      add(heart);
    }
  }

  // Update the kill count display
  void updateKills(int kills) {
    killsLabel.text = 'Kills: $kills';
  }

  // Update health hearts display
  void updateHealth(int current, int max) {
    // Update hearts: filled (❤) for current health, outlined (♡) for missing
    for (int i = 0; i < max; i++) {
      if (i < current) {
        _healthHearts[i].text = '❤'; // Filled heart
        _healthHearts[i].textRenderer = TextPaint(
          style: const TextStyle(fontSize: 24, color: Colors.red),
        );
      } else {
        _healthHearts[i].text = '♡'; // Outlined heart
        _healthHearts[i].textRenderer = TextPaint(
          style: const TextStyle(fontSize: 24, color: Colors.grey),
        );
      }
    }
  }

}