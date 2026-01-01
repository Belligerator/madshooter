import 'package:flutter/material.dart';
import 'base_enemy.dart';
import 'behaviors/movement_behavior.dart';

class HeavySoldier extends BaseEnemy {
  HeavySoldier({
    double? spawnXPercent,
    double spawnYOffset = 0.0,
    int dropUpgradePoints = 0,
    bool destroyedOnPlayerCollision = true,
    MovementBehavior? movementBehavior,
  }) : super(
    maxHealth: 500,
    enemyColor: Colors.purple,
    enemyRadius: 16.0, // Bigger than basic soldier (12.0)
    spawnXPercent: spawnXPercent,
    spawnYOffset: spawnYOffset,
    dropUpgradePoints: dropUpgradePoints,
    destroyedOnPlayerCollision: destroyedOnPlayerCollision,
    movementBehavior: movementBehavior,
  );

  @override
  double getSpeed() => super.getSpeed() * 0.5;
}
