import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/player.dart';
import 'components/road.dart';
import 'components/virtual_joystick.dart';

class ShootingGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  late Player player;
  late Road road;
  late VirtualJoystick joystick;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add road background
    road = Road();
    add(road);

    // Add player
    player = Player();
    add(player);

    // Add virtual joystick
    joystick = VirtualJoystick(
      knob: CircleComponent(radius: 15, paint: Paint()..color = Colors.blue),
      background: CircleComponent(radius: 50, paint: Paint()..color = Colors.grey.withOpacity(0.5)),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(joystick);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Move player based on joystick input
    if (!joystick.delta.isZero()) {
      player.move(joystick.delta.x);
    }
  }
}
