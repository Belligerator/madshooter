import 'package:flutter/material.dart';
import 'base_enemy.dart';

class HeavySoldier extends BaseEnemy {
  // Spawn configuration for heavy soldiers
  static const double spawnInterval = 8.0; // Spawn every 5 seconds
  static const int soldiersPerSpawn = 1;   // Spawn 1 at a time

  HeavySoldier({
    double? spawnXPercent,
    int dropUpgradePoints = 0,
    bool destroyedOnPlayerCollision = true,
  }) : super(
    maxHealth: 10,
    enemyColor: Colors.purple,
    enemyRadius: 16.0, // Bigger than basic soldier (12.0)
    spawnXPercent: spawnXPercent,
    dropUpgradePoints: dropUpgradePoints,
    destroyedOnPlayerCollision: destroyedOnPlayerCollision,
  );

  @override
  double getSpeed() => super.getSpeed() * 0.5;
}