import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../shooting_game.dart';

class PlayerSlider extends PositionComponent with HasGameRef<ShootingGame>, DragCallbacks {
  bool isDragging = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Control area covers full screen for free movement
    position = Vector2(0, 0);
    size = Vector2(gameRef.size.x, gameRef.size.y);

    // Set high priority to capture touch events
    priority = 500;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    // Don't move player on touch - only on drag
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!isDragging) return false;

    // Move player by same delta as thumb (1:1 relative movement)
    gameRef.player.moveByDelta(event.localDelta.x, event.localDelta.y);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    return true;
  }
}
