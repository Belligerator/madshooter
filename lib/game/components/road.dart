import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../shooting_game.dart';

class Road extends Component with HasGameRef<ShootingGame> {
  late List<RectangleComponent> roadSegments;
  late List<RectangleComponent> centerDashes;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create static road segments
    roadSegments = [];
    centerDashes = [];

    // Create one large road that covers the entire game world
    final screenHeight = gameRef.size.y;
    final headerHeight = 80.0;
    final gameAreaHeight = screenHeight - headerHeight;

    // Single road segment covering entire game area (starting at world Y=0)
    final roadSegment = RectangleComponent(
      size: Vector2(gameRef.roadWidth, gameAreaHeight),
      position: Vector2(
          gameRef.size.x / 2 - gameRef.roadWidth / 2,
          0  // World coordinates start at Y=0 (below header)
      ),
      paint: Paint()..color = Colors.grey[800]!,
    );
    roadSegments.add(roadSegment);
    add(roadSegment);

    // Create dashed center line
    const double dashHeight = 20.0;
    const double dashGap = 15.0;
    const double dashWidth = 4.0;

    final numberOfDashes = (gameAreaHeight / (dashHeight + dashGap)).ceil();

    for (int i = 0; i < numberOfDashes; i++) {
      final dashY = i * (dashHeight + dashGap);  // Start from world Y=0

      final dash = RectangleComponent(
        size: Vector2(dashWidth, dashHeight),
        position: Vector2(
            gameRef.size.x / 2 - dashWidth / 2, // Center of road
            dashY
        ),
        paint: Paint()..color = Colors.white,
      );
      centerDashes.add(dash);
      add(dash);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // No movement - road is now static!
  }

  // Helper method to get lane center positions
  Vector2 getLeftLaneCenter() {
    return Vector2(gameRef.size.x / 2 - gameRef.roadWidth / 4, 0);
  }

  Vector2 getRightLaneCenter() {
    return Vector2(gameRef.size.x / 2 + gameRef.roadWidth / 4, 0);
  }
}