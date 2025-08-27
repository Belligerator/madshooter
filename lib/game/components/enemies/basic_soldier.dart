import 'package:flutter/material.dart';
import 'base_enemy.dart';

class BasicSoldier extends BaseEnemy {
  // Spawn configuration for basic soldiers
  static const double spawnInterval = 0.3; // Spawn every 1 second
  static const int soldiersPerSpawn = 1;   // Spawn 2 at a time

  BasicSoldier() : super(
    maxHealth: 1,
    enemyColor: Colors.red,
    enemyRadius: 12.0,
  );
}