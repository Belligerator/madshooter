import 'package:flutter/material.dart';

import 'base_enemy.dart';

class HeavySoldier extends BaseEnemy {
  HeavySoldier()
    : super(
        maxHealth: 5,
        enemyColor: Colors.purple,
        enemyRadius: 16.0, // Bigger than basic soldier (12.0)
      );

  @override
  double getSpeed() => super.getSpeed() * 0.9; // 10% slower than basic soldiers
}
