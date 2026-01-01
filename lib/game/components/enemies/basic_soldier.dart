import 'package:flutter/material.dart';
import 'base_enemy.dart';
import 'behaviors/movement_behavior.dart';

class BasicSoldier extends BaseEnemy {
  BasicSoldier({
    double? spawnXPercent,
    int dropUpgradePoints = 0,
    bool destroyedOnPlayerCollision = true,
    MovementBehavior? movementBehavior,
  }) : super(
    maxHealth: 150,
    enemyColor: Colors.red,
    enemyRadius: 12.0,
    spawnXPercent: spawnXPercent,
    dropUpgradePoints: dropUpgradePoints,
    destroyedOnPlayerCollision: destroyedOnPlayerCollision,
    movementBehavior: movementBehavior,
  );
}