import 'package:flutter/material.dart';
import 'base_enemy.dart';

class HeavySoldier extends BaseEnemy {
  HeavySoldier({
    double? spawnXPercent,
    int dropUpgradePoints = 0,
    bool destroyedOnPlayerCollision = true,
  }) : super(
    maxHealth: 500,
    enemyColor: Colors.purple,
    enemyRadius: 16.0, // Bigger than basic soldier (12.0)
    spawnXPercent: spawnXPercent,
    dropUpgradePoints: dropUpgradePoints,
    destroyedOnPlayerCollision: destroyedOnPlayerCollision,
  );

  @override
  double getSpeed() => super.getSpeed() * 0.5;
}