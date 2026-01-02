import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'components/player.dart';
import 'components/ally.dart';
import 'components/space_background.dart';
import 'components/player_slider.dart';
import 'components/enemies/base_enemy.dart';
import 'components/enemies/basic_soldier.dart';
import 'components/enemies/heavy_soldier.dart';
import 'components/enemies/enemy_pool.dart';
import 'components/explosion_effect.dart';
import 'components/header.dart';
import 'game_config.dart';
import 'levels/level_manager.dart';
import 'levels/level_state.dart';

// Tiered upgrade system - Operation Spacehog style
enum UpgradeTier {
  bulletSize, // Tier 1: 1 UP
  fireRate, // Tier 2: 2 UP
  ally, // Tier 3: 3+ UP
}

class ShootingGame extends FlameGame with HasQuadTreeCollisionDetection, HasKeyboardHandlerComponents {
  late Player player;
  late SpaceBackground spaceBackground;
  late PlayerSlider playerSlider;
  late Header header;
  late LevelManager levelManager;

  // Pre-cached enemy sprites for performance
  late Sprite basicSoldierSprite;
  late Sprite heavySoldierSprite;

  // Enemy object pools for performance
  late EnemyPool<BasicSoldier> basicSoldierPool;
  late EnemyPool<HeavySoldier> heavySoldierPool;

  // UI Layout constants
  static const double headerHeight = 80.0;

  // Game state
  bool isPaused = false;

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

  // Event callbacks for UI
  VoidCallback? onLevelComplete;
  VoidCallback? onLevelFailed;
  VoidCallback? onStateChanged;

  // Constructor to accept safe area padding
  final int initialLevelId;
  ShootingGame({required this.initialLevelId});

  // Game area dimensions (excluding header)
  double get gameWidth => size.x;
  double get gameHeight => size.y - headerHeight / 2;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Pre-cache enemy sprites for performance (load once, reuse for all enemies)
    basicSoldierSprite = await loadSprite('enemies/EnemyShip1_Base.webp');
    heavySoldierSprite = await loadSprite('enemies/Enemy_Tank_Base.webp');

    // Set up world and camera
    final worldComponent = World();
    final cameraComponent = CameraComponent(world: worldComponent);

    // Use fixed size viewport positioned below header
    cameraComponent.viewport = FixedSizeViewport(gameWidth, gameHeight);
    cameraComponent.viewport.position = Vector2(0, headerHeight);

    // Viewfinder looks at center of game world
    cameraComponent.viewfinder.position = Vector2(0, 0);
    cameraComponent.viewfinder.anchor = Anchor.topLeft;

    await addAll([cameraComponent, worldComponent]);
    camera = cameraComponent;
    world = worldComponent;

    // Configure QuadTree broadphase for better collision performance with many enemies
    // Bounds cover game area + buffer for spawning enemies above and bullets traveling up
    initializeCollisionDetection(
      mapDimensions: Rect.fromLTWH(
        0,                  // Left bound (world X origin)
        -200,               // Top bound (buffer for enemies spawning above screen)
        gameWidth,          // Width (full game width)
        gameHeight + 400,   // Height (game area + spawn buffer above + exit buffer below)
      ),
    );

    // Add all game components to world
    spaceBackground = SpaceBackground(initialLevelId: initialLevelId);
    player = Player();
    playerSlider = PlayerSlider();

    worldComponent.add(spaceBackground);
    worldComponent.add(player);
    worldComponent.add(playerSlider);

    // Add header directly to game (screen space, not world space)
    header = Header();
    add(header);

    // Initialize level manager
    levelManager = LevelManager(this);

    // Initialize enemy pools (pre-populate with 50 enemies each)
    basicSoldierPool = EnemyPool<BasicSoldier>(
      () => BasicSoldier(cachedSprite: basicSoldierSprite),
      worldComponent,
      initialSize: 1,
    );
    heavySoldierPool = EnemyPool<HeavySoldier>(
      () => HeavySoldier(cachedSprite: heavySoldierSprite),
      worldComponent,
      initialSize: 1,
    );

    // Don't automatically load level here - let the GameScreen handle it
    // The level will be loaded via loadAndStartLevel() called from GameScreen
  }

  @override
  void update(double dt) {
    // Don't update if game is paused
    if (isPaused) return;

    // Clamp dt to prevent tunneling (max 20 FPS step)
    // Bullet speed 300 * 0.05 = 15px. Bullet hitbox height ~18px.
    // This ensures the bullet never moves further than its own size in one frame.
    final clampedDt = min(dt, 0.05);

    super.update(clampedDt);

    // Update ally positions to follow main player
    for (final ally in allies) {
      ally.updatePosition(player.position);
    }

    // Update level manager
    levelManager.update(clampedDt);
    // Clean up dead enemies from our tracking list
    _enemies.removeWhere((enemy) => enemy.isRemoved);
  }

  // Public method to spawn enemy and track it
  void spawnEnemy(BaseEnemy enemy) {
    _enemies.add(enemy);
    world.add(enemy);
  }

  // Track enemy from pool (already added to world by pool)
  void trackEnemy(BaseEnemy enemy) {
    _enemies.add(enemy);
  }

  // Called when a soldier is killed by bullet collision
  void onSoldierKilled() {
    killCount++;
    levelManager.onEnemyKilled();
    _updateLabels();
  }

  // Called when player takes damage
  void takeDamage(int damage) {
    playerHealth -= damage;
    totalDamage += damage;
    levelManager.onDamageTaken(damage);

    // Check for death
    if (playerHealth <= 0) {
      playerHealth = 0;
      _onPlayerDestroyed();
    }

    _updateLabels();
  }

  // Handle player destruction with explosion effect
  void _onPlayerDestroyed() {
    // Spawn explosion effect at player center
    final explosion = ExplosionEffect(origin: player.position.clone());
    world.add(explosion);

    // Hide player immediately (remove from world but keep reference)
    player.removeFromParent();

    // Notify level manager of player death (which handles the delay internally)
    levelManager.onPlayerDeath();
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
  Future<void> loadAndStartLevel(int levelId) async {
    await levelManager.loadLevel(levelId);
    levelManager.startLevel();
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

    // Re-add player if it was removed (e.g., after death)
    if (player.isRemoved) {
      world.add(player);
      // Reset player position
      player.position = Vector2(gameWidth / 2, gameHeight - Player.playerBottomPositionY);
    }

    // Reset stats
    killCount = 0;
    totalDamage = 0;

    // Reset upgrades
    bulletSizeMultiplier = 1.0;
    additionalFireRate = 0.0;
    upgradePoints = 0;
    playerHealth = maxPlayerHealth;
    currentMessage = null;

    // Update UI
    _updateLabels();
    updateUpgradeLabels();
  }

  // Weapon upgrade methods with max limits from config
  bool upgradeBulletSize(double multiplier) {
    if (bulletSizeMultiplier >= GameConfig.maxBulletSizeMultiplier) {
      return false; // Already at max
    }

    bulletSizeMultiplier = (bulletSizeMultiplier + multiplier).clamp(1.0, GameConfig.maxBulletSizeMultiplier);
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
    if (allyCount >= GameConfig.maxAllyCount) {
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
    world.add(ally);

    updateUpgradeLabels(); // Update UI
    return true; // Upgrade applied
  }

  void addUpgradePoint() {
    // Just increment UP - collecting more after 3 does nothing until upgrade applied
    if (upgradePoints < maxUpgradePoints) {
      upgradePoints++;
      onStateChanged?.call();
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
      onStateChanged?.call();
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
    onStateChanged?.call();
  }

  void clearMessage() {
    currentMessage = null;
    onStateChanged?.call();
  }

  // Get current bullet damage with upgrades applied
  int getBulletDamage() {
    const baseDamage = 100;
    return baseDamage + (bulletSizeLevel * 50);
  }

  // Get current fire rate with upgrades applied (shots per second)
  double getFireRate() {
    return GameConfig.baseFireRate + additionalFireRate;
  }

  // Get current fire interval (seconds between shots) - for internal use
  double getFireInterval() {
    return 1.0 / getFireRate(); // Convert shots per second to seconds between shots
  }

  // Helper method to get the game area height (excluding header and safe areas)
  double get gameAreaHeight => size.y - headerHeight;

  // Helper method to get the game area start position (including safe area)
  double get gameAreaTop => headerHeight;

  // Level status getters for UI
  bool get isLevelActive => levelManager.levelState == LevelState.running;
  bool get isLevelCompleted => levelManager.levelState == LevelState.completed;
  bool get isLevelFailed => levelManager.levelState == LevelState.failed;

  String get currentLevelName => levelManager.currentLevel?.name ?? '';
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
