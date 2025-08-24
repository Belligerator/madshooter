import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';

class Road extends Component with HasGameRef<ShootingGame> {
  static const double roadWidth = 200.0;
  static const double laneWidth = roadWidth / 2;
  static const double scrollSpeed = 100.0;

  late List<RectangleComponent> roadSegments;
  late List<RectangleComponent> laneLines;
  late List<RectangleComponent> trees;
  late double segmentHeight;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create road segments for seamless scrolling
    roadSegments = [];
    laneLines = [];
    trees = [];

    // Create multiple road segments to fill screen + buffer (excluding header)
    final screenHeight = gameRef.size.y;
    final gameAreaHeight = screenHeight;

    segmentHeight = gameAreaHeight / 4;
    final segmentCount = 4 + 1; // Extra segments for smooth scrolling

    for (int i = 0; i < segmentCount; i++) {
      // Road background
      final roadSegment = RectangleComponent(
        size: Vector2(roadWidth, segmentHeight + 2),
        position: Vector2(
            gameRef.size.x / 2 - roadWidth / 2,
            screenHeight - (i * segmentHeight)
        ),
        paint: Paint()..color = Colors.grey[800]!,
      );
      roadSegments.add(roadSegment);
      add(roadSegment);

      // Lane divider line (white instead of yellow)
      final laneLine = RectangleComponent(
        size: Vector2(4, segmentHeight + 2),
        position: Vector2(
            gameRef.size.x / 2 - 2,
            screenHeight - (i * segmentHeight)
        ),
        paint: Paint()..color = Colors.white,
      );
      laneLines.add(laneLine);
      add(laneLine);

      // DEBUG: Add tree marker at the beginning of each segment
      final tree = RectangleComponent(
        size: Vector2(15, 15),
        position: Vector2(
          gameRef.size.x / 2 - roadWidth / 2 - 20, // Left side of road
          screenHeight - (i * segmentHeight),
        ),
        paint: Paint()..color = Colors.green,
        children: [
          TextComponent(
            text: '$i',
            position: Vector2(0, 0),
            textRenderer: TextPaint(style: const TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ],
      );
      trees.add(tree);
      add(tree);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move all road segments down
    for (final segment in roadSegments) {
      segment.position.y += scrollSpeed * dt;

      // Reset position when segment goes off screen
      if (segment.position.y > gameRef.size.y) {
        segment.position.y = -segmentHeight;
      }
    }

    // Move all lane lines down
    for (final line in laneLines) {
      line.position.y += scrollSpeed * dt;

      // Reset position when line goes off screen
      if (line.position.y > gameRef.size.y) {
        line.position.y = -segmentHeight;
      }
    }

    for (final tree in trees) {
      tree.position.y += scrollSpeed * dt;

      // Reset position when line goes off screen
      if (tree.position.y > gameRef.size.y) {
        tree.position.y = -segmentHeight;
      }
    }
  }

  // Helper method to get lane center positions
  Vector2 getLeftLaneCenter() {
    return Vector2(gameRef.size.x / 2 - laneWidth / 2, 0);
  }

  Vector2 getRightLaneCenter() {
    return Vector2(gameRef.size.x / 2 + laneWidth / 2, 0);
  }
}