import 'package:flutter/material.dart';
import 'base_enemy.dart';

class BasicSoldier extends BaseEnemy {
  BasicSoldier({
    double? spawnXPercent,
    int dropUpgradePoints = 0,
    bool destroyedOnPlayerCollision = true,
  }) : super(
    maxHealth: 150,
    enemyColor: Colors.red,
    enemyRadius: 12.0,
    spawnXPercent: spawnXPercent,
    dropUpgradePoints: dropUpgradePoints,
    destroyedOnPlayerCollision: destroyedOnPlayerCollision,
  );
}