import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';

class Road extends Component with HasGameReference<ShootingGame> {
  late List<RectangleComponent> roadSegments;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create static road segments
    roadSegments = [];

    // Create one large road that covers the entire game world
    final gameAreaHeight = game.gameHeight;

    // Single road segment covering entire game area (starting at world Y=0)
    final roadSegment = RectangleComponent(
      size: Vector2(game.roadWidth, gameAreaHeight),
      position: Vector2(
          game.gameWidth / 2 - game.roadWidth / 2,
          0  // World coordinates start at Y=0 (below header)
      ),
      paint: Paint()..color = Colors.grey[800]!,
    );
    roadSegments.add(roadSegment);
    add(roadSegment);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // No movement - road is now static!
  }

  // Helper method to get lane center positions
  Vector2 getLeftLaneCenter() {
    return Vector2(game.gameWidth / 2 - game.roadWidth / 4, 0);
  }

  Vector2 getRightLaneCenter() {
    return Vector2(game.gameWidth / 2 + game.roadWidth / 4, 0);
  }
}
