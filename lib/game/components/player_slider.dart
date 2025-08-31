import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:madshooter/game/components/player.dart';

import '../shooting_game.dart';

class PlayerSlider extends PositionComponent with HasGameRef<ShootingGame>, TapCallbacks, DragCallbacks {
  late RectangleComponent sliderTrack;
  late RectangleComponent sliderThumb;

  double sliderValue = 0.5; // 0.0 = left, 0.5 = center, 1.0 = right
  bool isDragging = false;

  static const double sliderHeight = 100.0;
  static const double thumbWidth = 100.0;
  static const double thumbHeight = 200.0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Calculate slider dimensions and position
    final sliderWidth = gameRef.roadWidth + thumbWidth; // Same width as road
    // thumbWidth - for top padding, same as width. Bottom padding will be to the bottom of the screen
    final sliderY = gameRef.size.y - Player.playerBottomPositionY - thumbWidth / 2;
    final sliderX = gameRef.size.x / 2 - sliderWidth / 2; // Centered

    // Set component position and size
    position = Vector2(sliderX, sliderY);
    size = Vector2(sliderWidth, thumbHeight);

    // Create slider thumb (draggable part)
    sliderThumb = RectangleComponent(
      size: Vector2(thumbWidth, thumbHeight),
      position: Vector2((sliderWidth - thumbWidth) * sliderValue, 0),
      paint: Paint()..color = Colors.transparent,
    );
    add(sliderThumb);

    // Set high priority to render above other components
    priority = 500;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    // No tap-to-jump functionality - only allow dragging the thumb
    return false;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    final localPoint = event.localPosition;

    // Check if drag starts specifically on the thumb
    final thumbRect = Rect.fromLTWH(sliderThumb.position.x, sliderThumb.position.y, thumbWidth, thumbHeight);

    if (thumbRect.contains(Offset(localPoint.x, localPoint.y))) {
      isDragging = true;
      return true;
    }

    return false;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (isDragging) {
      // Use delta to update position
      final deltaX = event.localDelta.x;
      final newThumbX = sliderThumb.position.x + deltaX;

      // Convert thumb position back to slider value
      sliderValue = (newThumbX / (size.x - thumbWidth)).clamp(0.0, 1.0);
      _updateSliderPosition();
      _notifyPlayerMovement();

      return true;
    }

    return false;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    isDragging = false;
    return true;
  }

  void _updateSliderPosition() {
    // Update thumb position based on slider value
    sliderThumb.position.x = (size.x - thumbWidth) * sliderValue;
  }

  void _notifyPlayerMovement() {
    // Convert slider value (0.0 to 1.0) to player position
    // 0.0 = left boundary, 1.0 = right boundary
    gameRef.player.moveToSliderPosition(sliderValue);
  }
}
