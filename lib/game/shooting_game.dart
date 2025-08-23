import 'dart:math';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/player.dart';
import 'components/road.dart';
import 'components/soldier.dart';
import 'components/virtual_joystick.dart';

class ShootingGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  late Player player;
  late Road road;
  late VirtualJoystick joystick;

  // Enemy spawning variables
  static const double spawnInterval = 5.0; // Spawn every 5 seconds
  static const int maxVisibleSoldiers = 50;
  static const int soldiersPerSpawn = 5;

  double _timeSinceLastSpawn = 0;
  final Random _random = Random();
  final List<Soldier> _soldiers = [];

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

    // Handle enemy spawning
    _handleEnemySpawning(dt);

    // Clean up dead soldiers from our tracking list
    _soldiers.removeWhere((soldier) => soldier.isRemoved);
  }

  void _handleEnemySpawning(double dt) {
    _timeSinceLastSpawn += dt;

    if (_timeSinceLastSpawn >= spawnInterval) {
      _spawnSoldiers();
      _timeSinceLastSpawn = 0;
    }
  }

  void _spawnSoldiers() {
    // Don't spawn if we already have too many soldiers
    if (_soldiers.length >= maxVisibleSoldiers) {
      return;
    }

    // Calculate how many soldiers we can spawn
    final remainingSlots = maxVisibleSoldiers - _soldiers.length;
    final soldiersToSpawn = math.min(soldiersPerSpawn, remainingSlots);

    for (int i = 0; i < soldiersToSpawn; i++) {
      final soldier = Soldier();
      _soldiers.add(soldier);
      add(soldier);
    }

    print('Spawned $soldiersToSpawn soldiers. Total: ${_soldiers.length}');
  }
}
