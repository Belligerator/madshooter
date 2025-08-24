import 'package:flutter/material.dart';

import 'base_enemy.dart';

class BasicSoldier extends BaseEnemy {
  BasicSoldier() : super(maxHealth: 1, enemyColor: Colors.red, enemyRadius: 12.0);
}
