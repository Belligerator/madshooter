import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'dart:math';
import 'components/player.dart';
import 'components/ally.dart';
import 'components/road.dart';
import 'components/player_slider.dart';
import 'components/enemies/base_enemy.dart';
import 'components/enemies/basic_soldier.dart';
import 'components/enemies/heavy_soldier.dart';
import 'components/header.dart';
import 'components/barrel.dart';
import 'upgrade_config.dart';
import 'levels/level_manager.dart';
import 'levels/level_state.dart';

// Tiered upgrade system - Operation Spacehog style
enum UpgradeTier {
  bulletSize,  // Tier 1: 1 UP
  fireRate,    // Tier 2: 2 UP
  ally,        // Tier 3: 3+ UP
}

class ShootingGame extends FlameGame with HasCollisionDetection, HasKeyboardHandlerComponents {
  late Player player;
  late Road road;
  late PlayerSlider playerSlider;
  late Header header;
  late LevelManager levelManager;

  // UI Layout constants
  static const double headerHeight = 80.0;
  final double roadWidth = 200.0; // Instance variable instead of static
  double safeAreaTop; // Changed to mutable for dynamic updates

  // Game state
  bool isPaused = false;
  bool isLevelMode = false;

  // Spawning timers (for free play mode)
  double _timeSinceLastBarrelSpawn = 0;
  double _timeSinceLastBasicSpawn = 0;
  double _timeSinceLastHeavySpawn = 0;

  final Random _random = Random();
  final List<BaseEnemy> _enemies = [];
  final List<Ally> allies = []; // Added the missing allies list
  int allyCount = 0; // Track current number of allies

  // Game statistics
  int killCount = 0;
  int totalDamage = 0; // Changed from escapedCount

  // Weapon upgrades
  double bulletSizeMultiplier = 1.0;
  double additionalFireRate = 0.0; // Additional shots per second

  // Upgrade points (UP) - max 3 for tiered upgrades
  int upgradePoints = 0;
  static const int maxUpgradePoints = 3;

  // Player health - one hit death
  int playerHealth = 1;
  static const int maxPlayerHealth = 1;

  // In-game messages
  String? currentMessage;

  // Constructor to accept safe area padding
  ShootingGame({this.safeAreaTop = 0.0});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add road background
    road = Road();
    add(road);

    // Add player
    player = Player();
    add(player);

    // Add player slider for movement control
    playerSlider = PlayerSlider();
    add(playerSlider);

    // Add header component (will render on top due to high priority)
    header = Header();
    add(header);

    // Initialize level manager
    levelManager = LevelManager(this);

    // Don't automatically load level here - let the GameScreen handle it
    // The level will be loaded via loadAndStartLevel() called from GameScreen
  }

  @override
  void update(double dt) {
    // Don't update if game is paused
    if (isPaused) return;

    super.update(dt);

    // Update ally positions to follow main player
    for (final ally in allies) {
      ally.updatePosition(player.position);
    }

    // Update level manager if in level mode
    if (isLevelMode) {
      levelManager.update(dt);
    } else {
      // Handle enemy spawning in free play mode only
      _handleBasicSoldierSpawning(dt);
      _handleHeavySoldierSpawning(dt);
      _handleBarrelSpawning(dt);
    }

    // Clean up dead enemies from our tracking list
    _enemies.removeWhere((enemy) {
      if (enemy.isRemoved) {
        return true; // Remove from tracking list
      }

      // Check if enemy escaped (reached bottom)
      if (enemy.position.y > size.y) {
        return true; // Just remove, no damage (damage only on collision now)
      }

      return false; // Keep in tracking list
    });
  }

  void _handleBasicSoldierSpawning(double dt) {
    _timeSinceLastBasicSpawn += dt;

    if (_timeSinceLastBasicSpawn >= BasicSoldier.spawnInterval) {
      _spawnBasicSoldiers();
      _timeSinceLastBasicSpawn = 0;
    }
  }

  void _handleHeavySoldierSpawning(double dt) {
    _timeSinceLastHeavySpawn += dt;

    if (_timeSinceLastHeavySpawn >= HeavySoldier.spawnInterval) {
      _spawnHeavySoldiers();
      _timeSinceLastHeavySpawn = 0;
    }
  }

  void _handleBarrelSpawning(double dt) {
    _timeSinceLastBarrelSpawn += dt;

    if (_timeSinceLastBarrelSpawn >= Barrel.spawnInterval) {
      _spawnBarrel();
      _timeSinceLastBarrelSpawn = 0;
    }
  }

  void _spawnBasicSoldiers() {
    for (int i = 0; i < BasicSoldier.soldiersPerSpawn; i++) {
      final enemy = BasicSoldier();
      spawnEnemy(enemy);
    }
  }

  void _spawnHeavySoldiers() {
    for (int i = 0; i < HeavySoldier.soldiersPerSpawn; i++) {
      final enemy = HeavySoldier();
      spawnEnemy(enemy);
    }
  }

  // Public method to spawn enemy and track it
  void spawnEnemy(BaseEnemy enemy) {
    _enemies.add(enemy);
    add(enemy);
  }

  void _spawnBarrel() {
    // Use probability-based barrel type selection
    final barrelType = BarrelType.getRandomBarrelType(_random);

    final barrel = Barrel(type: barrelType);
    add(barrel);
  }

  // Called when a soldier is killed by bullet collision
  void onSoldierKilled() {
    killCount++;

    // Notify level manager if in level mode
    if (isLevelMode) {
      levelManager.onEnemyKilled();
    }

    _updateLabels();
  }

  // Called when player takes damage from escaped enemies
  void takeDamage(int damage) {
    playerHealth -= damage;
    totalDamage += damage;

    // Notify level manager if in level mode (before death check to track final damage)
    if (isLevelMode) {
      levelManager.onDamageTaken(damage);
    }

    // Check for death
    if (playerHealth <= 0) {
      playerHealth = 0; // Clamp at 0
      if (isLevelMode) {
        levelManager.onPlayerDeath();
      }
    }

    _updateLabels();
  }

  void _updateLabels() {
    header.updateKills(killCount);
    header.updateHealth(playerHealth, maxPlayerHealth);
  }

  void updateUpgradeLabels() {
    // Upgrade labels removed from UI
  }

  // Pause/Resume methods (called from Flutter widget)
  void pauseGame() {
    isPaused = true;
    pauseEngine(); // Stops the game loop
    print('Game paused');
  }

  void resumeGame() {
    isPaused = false;
    resumeEngine(); // Resumes the game loop
    print('Game resumed');
  }

  // Level management methods
  void setLevelMode(bool enabled) {
    isLevelMode = enabled;
    if (!enabled) {
      // Reset to free play mode
      levelManager.levelState = LevelState.notStarted;
    }
  }

  Future<void> loadAndStartLevel(int levelId) async {
    await levelManager.loadLevel(levelId);
    levelManager.startLevel();
    isLevelMode = true;
  }

  // Reset game state for new level or restart
  void resetGameState() {
    // Clear all enemies
    for (final enemy in _enemies) {
      enemy.removeFromParent();
    }
    _enemies.clear();

    // Clear all allies
    for (final ally in allies) {
      ally.removeFromParent();
    }
    allies.clear();
    allyCount = 0;

    // Reset stats
    killCount = 0;
    totalDamage = 0;

    // Reset upgrades
    bulletSizeMultiplier = 1.0;
    additionalFireRate = 0.0;
    upgradePoints = 0;
    playerHealth = maxPlayerHealth;
    currentMessage = null;

    // Reset spawning timers
    _timeSinceLastBarrelSpawn = 0;
    _timeSinceLastBasicSpawn = 0;
    _timeSinceLastHeavySpawn = 0;

    // Update UI
    _updateLabels();
    updateUpgradeLabels();
  }

  // Weapon upgrade methods with max limits from config
  bool upgradeBulletSize(double multiplier) {
    if (bulletSizeMultiplier >= UpgradeConfig.maxBulletSizeMultiplier) {
      return false; // Already at max
    }

    bulletSizeMultiplier = (bulletSizeMultiplier + multiplier).clamp(1.0, UpgradeConfig.maxBulletSizeMultiplier);
    updateUpgradeLabels(); // Update UI
    return true; // Upgrade applied
  }

  bool upgradeFireRate(double additionalRate) {
    // Max additional fire rate would be 10.0 shots/sec (15 total - 5 base = 10 additional)
    const double maxAdditionalRate = 10.0;
    if (additionalFireRate >= maxAdditionalRate) {
      return false; // Already at max
    }

    additionalFireRate = (additionalFireRate + additionalRate).clamp(0.0, maxAdditionalRate);
    updateUpgradeLabels(); // Update UI
    return true; // Upgrade applied
  }

  bool addAlly() {
    if (allyCount >= UpgradeConfig.maxAllyCount) {
      return false; // Already at max allies
    }

    allyCount++;

    // Create ally with random offset position around player (closer and behind)
    const double maxOffset = 10.0; // Max pixels from player
    const double behindOffset = 15.0; // How far behind player

    Vector2 allyOffset = Vector2(
      (_random.nextDouble() - 0.5) * 2 * maxOffset, // Random X: -10 to +10
      behindOffset + (_random.nextDouble() * maxOffset), // Random Y: 15 to 25 (behind player)
    );

    final ally = Ally(offsetFromPlayer: allyOffset);
    allies.add(ally);
    add(ally);

    updateUpgradeLabels(); // Update UI
    return true; // Upgrade applied
  }

  void addUpgradePoint() {
    // Just increment UP - collecting more after 3 does nothing until upgrade applied
    if (upgradePoints < maxUpgradePoints) {
      upgradePoints++;
    }
    // When at max, collecting more UP does nothing (user must upgrade first)
  }

  // Check if a specific tier is available based on UP count
  bool isTierAvailable(UpgradeTier tier) {
    switch (tier) {
      case UpgradeTier.bulletSize:
        return upgradePoints >= 1;
      case UpgradeTier.fireRate:
        return upgradePoints >= 2;
      case UpgradeTier.ally:
        return upgradePoints >= 3;
    }
  }

  // Get highest available tier (for UP button)
  UpgradeTier? getHighestAvailableTier() {
    if (upgradePoints >= 3) return UpgradeTier.ally;
    if (upgradePoints >= 2) return UpgradeTier.fireRate;
    if (upgradePoints >= 1) return UpgradeTier.bulletSize;
    return null;
  }

  // Legacy getter for compatibility
  UpgradeTier? getCurrentTier() => getHighestAvailableTier();

  // Apply specific upgrade, reset UP
  bool applyUpgrade(UpgradeTier tier) {
    if (!isTierAvailable(tier)) return false;

    bool applied = false;
    switch (tier) {
      case UpgradeTier.bulletSize:
        applied = upgradeBulletSize(0.2);
        break;
      case UpgradeTier.fireRate:
        applied = upgradeFireRate(1.0);
        break;
      case UpgradeTier.ally:
        applied = addAlly();
        break;
    }

    if (applied) {
      upgradePoints = 0; // Reset UP after any upgrade
    }
    return applied;
  }

  // Legacy method for compatibility
  bool applyTieredUpgrade() {
    final tier = getHighestAvailableTier();
    if (tier == null) return false;
    return applyUpgrade(tier);
  }

  // Message display methods
  void showMessage(String message) {
    currentMessage = message;
  }

  void clearMessage() {
    currentMessage = null;
  }

  // Get current bullet size with upgrades applied
  Vector2 getBulletSize() {
    final baseSize = Vector2(UpgradeConfig.baseBulletWidth, UpgradeConfig.baseBulletHeight);
    return Vector2(baseSize.x * bulletSizeMultiplier, baseSize.y * bulletSizeMultiplier);
  }

  // Get current fire rate with upgrades applied (shots per second)
  double getFireRate() {
    return UpgradeConfig.baseFireRate + additionalFireRate;
  }

  // Get current fire interval (seconds between shots) - for internal use
  double getFireInterval() {
    return 1.0 / getFireRate(); // Convert shots per second to seconds between shots
  }

  // Helper method to get the game area height (excluding header and safe areas)
  double get gameAreaHeight => size.y - headerHeight - safeAreaTop;

  // Helper method to get the game area start position (including safe area)
  double get gameAreaTop => headerHeight + safeAreaTop;

  // Level status getters for UI
  bool get isLevelActive => isLevelMode && levelManager.levelState == LevelState.running;
  bool get isLevelCompleted => isLevelMode && levelManager.levelState == LevelState.completed;
  bool get isLevelFailed => isLevelMode && levelManager.levelState == LevelState.failed;

  String get currentLevelName => levelManager.currentLevel?.name ?? 'Free Play';
  double get levelProgress => levelManager.progress;
  String get levelTimeRemaining => levelManager.timeRemaining;

  // Level stats for end-game dialogs
  int get levelKills => levelManager.levelKills;
  int get levelDamage => levelManager.levelDamage;
  int get enemiesAlive => _enemies.length;
  double get levelTime => levelManager.levelTime;
  int? get currentLevelId => levelManager.currentLevel?.levelId;

  // Star rating getters
  int get totalEnemiesSpawned => levelManager.totalEnemiesSpawned;
  double get killPercentage => levelManager.killPercentage;
  int get starsEarned => levelManager.starsEarned;

  // Upgrade level getters (for UI display)
  int get bulletSizeLevel => ((bulletSizeMultiplier - 1.0) / 0.2).round();
  int get fireRateLevel => (additionalFireRate / 1.0).round();
  int get allyLevel => allyCount;
}