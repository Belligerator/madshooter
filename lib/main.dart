import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/shooting_game.dart';

void main() {
  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shooting Game Prototype',
      home: GameWidget(game: ShootingGame()),
    );
  }
}