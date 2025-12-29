import 'package:flutter/material.dart';
import 'base_enemy.dart';

class BasicSoldier extends BaseEnemy {
  // Spawn configuration for basic soldiers
  static const double spawnInterval = 0.3; // Spawn every 1 second
  static const int soldiersPerSpawn = 1;   // Spawn 2 at a time

  BasicSoldier({
    double? spawnXPercent,
    int dropUpgradePoints = 0,
    bool destroyedOnPlayerCollision = true,
  }) : super(
    maxHealth: 1,
    enemyColor: Colors.red,
    enemyRadius: 12.0,
    spawnXPercent: spawnXPercent,
    dropUpgradePoints: dropUpgradePoints,
    destroyedOnPlayerCollision: destroyedOnPlayerCollision,
  );
}