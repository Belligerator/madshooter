// lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'dart:async';
import '../game/shooting_game.dart';
import '../game/levels/level_manager.dart';
import '../widgets/dialogs/level_complete_dialog.dart';
import '../widgets/dialogs/level_failed_dialog.dart';
import '../widgets/up_meter.dart';
import '../widgets/game_message_banner.dart';
import '../services/progress_service.dart';
import 'level_selection_screen.dart';

class GameScreen extends StatefulWidget {
  final int levelId;

  GameScreen({required this.levelId});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late ShootingGame game;
  bool isPaused = false;
  Key gameKey = UniqueKey();
  Timer? _uiUpdateTimer;
  bool _gameInitialized = false;
  bool _endGameDialogShown = false;
  String? _displayedMessage;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _initFuture = _initializeGameMode();
    WidgetsBinding.instance.addObserver(this);

    // Start UI update timer for level progress
    _startUIUpdateTimer();
  }

  void _initializeGame() {
    game = ShootingGame(initialLevelId: widget.levelId);
  }

  void _startUIUpdateTimer() {
    // Update UI every 100ms for smooth progress bar and timer updates
    _uiUpdateTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted && !isPaused) {
        // Check for level end
        if (!_endGameDialogShown) {
          if (game.isLevelCompleted) {
            print('GameScreen: Level Completed detected. Showing dialog.');
            _endGameDialogShown = true;
            _showLevelCompleteDialog();
          } else if (game.isLevelFailed) {
            print('GameScreen: Level Failed detected. Showing dialog.');
            _endGameDialogShown = true;
            _showLevelFailedDialog();
          }
        }

        // Check for new message
        if (game.currentMessage != null && _displayedMessage != game.currentMessage) {
          _displayedMessage = game.currentMessage;
        }

        setState(() {
          // This will trigger a rebuild with updated game state
        });
      }
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseGame();
        break;
      case AppLifecycleState.resumed:
        // Don't auto-resume, let user choose
        break;
      case AppLifecycleState.inactive:
        // Don't pause for inactive (e.g., notification pull-down)
        break;
    }
  }

  Future<void> _initializeGameMode() async {
    if (_gameInitialized) return;

    _gameInitialized = true;
    print('Initializing game mode for level ${widget.levelId}...');

    // Wait a bit to ensure game is fully loaded and attached
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await game.loadAndStartLevel(widget.levelId);
      print('Level loaded and started.');
    } catch (e) {
      print('Error starting level: $e');
    }
  }

  void _pauseGame() {
    setState(() {
      isPaused = true;
    });
    game.pauseGame();
  }

  void _resumeGame() {
    setState(() {
      isPaused = false;
    });
    game.resumeGame();
  }

  void _resetGame() {
    if (!isPaused) {
      _pauseGame();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Restart?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to restart?', style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeGame();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                isPaused = false;
                gameKey = UniqueKey();
                _gameInitialized = false; // Reset initialization flag
                _initializeGame();
              });
              // Re-initialize the game mode after creating new game instance
              Future.delayed(Duration(milliseconds: 100), () {
                _initializeGameMode();
              });
              // Restart the UI update timer
              _startUIUpdateTimer();
            },
            child: Text('Restart', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showGameMenu() {
    if (!isPaused) {
      _pauseGame();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Game Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow, color: Colors.green),
              title: Text('Resume', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                _resumeGame();
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.orange),
              title: Text('Restart', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
            ListTile(
              leading: Icon(Icons.list, color: Colors.blue),
              title: Text('Level Select', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LevelSelectionScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.grey),
              title: Text('Main Menu', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLevelCompleteDialog() async {
    _pauseGame();

    // Check if next level exists
    final nextLevelData = await LevelManager.loadLevelData(widget.levelId + 1);
    final hasNextLevel = nextLevelData != null;

    // Save stars to persistence
    final starsEarned = game.starsEarned;
    await ProgressService.saveBestStars(widget.levelId, starsEarned);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LevelCompleteDialog(
        timeSurvived: game.levelTime,
        kills: game.levelKills,
        damageTaken: game.levelDamage,
        hasNextLevel: hasNextLevel,
        starsEarned: starsEarned,
        totalEnemies: game.totalEnemiesSpawned,
        killPercentage: game.killPercentage,
        onNextLevel: () {
          Navigator.of(dialogContext).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => GameScreen(levelId: widget.levelId + 1)),
          );
        },
        onRestart: () {
          Navigator.of(dialogContext).pop();
          _restartLevel();
        },
        onLevelSelect: () {
          Navigator.of(dialogContext).pop();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LevelSelectionScreen()));
        },
      ),
    );
  }

  void _showLevelFailedDialog() {
    _pauseGame();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LevelFailedDialog(
        timeSurvived: game.levelTime,
        kills: game.levelKills,
        onRestart: () {
          Navigator.of(dialogContext).pop();
          _restartLevel();
        },
        onLevelSelect: () {
          Navigator.of(dialogContext).pop();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LevelSelectionScreen()));
        },
      ),
    );
  }

  void _restartLevel() {
    setState(() {
      isPaused = false;
      gameKey = UniqueKey();
      _gameInitialized = false;
      _endGameDialogShown = false;
      _initializeGame();
      _initFuture = _initializeGameMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        body: SafeArea(
          child: FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              return Stack(
                children: [
                  // Game widget
                  GameWidget(key: gameKey, game: game),
          
                  // Menu button (moved to where pause button was)
                  Positioned(
                    top: 15,
                    right: 20,
                    child: Container(
                      width: 50,
                      height: 50,
                      child: FloatingActionButton(
                        heroTag: "menu_button",
                        onPressed: _showGameMenu,
                        backgroundColor: Colors.black.withOpacity(0.7),
                        child: Icon(Icons.menu, color: Colors.white, size: 24),
                        mini: true,
                      ),
                    ),
                  ),
          
                  // UP meter in header area (left side)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: UpMeter(
                      upgradePoints: game.upgradePoints,
                      bulletSizeLevel: game.bulletSizeLevel,
                      fireRateLevel: game.fireRateLevel,
                      allyLevel: game.allyLevel,
                      onUpgradeTap: (tier) {
                        game.applyUpgrade(tier);
                      },
                    ),
                  ),
          
                  // Upgrade button at bottom right near thumb
                  Positioned(
                    right: 20,
                    bottom: 120,
                    child: UpgradeButton(
                      canUpgrade: game.getHighestAvailableTier() != null,
                      onTap: () {
                        final tier = game.getHighestAvailableTier();
                        if (tier != null) game.applyUpgrade(tier);
                      },
                    ),
                  ),
          
                  // In-game message banner
                  if (_displayedMessage != null)
                    Positioned(
                      top: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GameMessageBanner(
                          key: ValueKey(_displayedMessage),
                          message: _displayedMessage!,
                          onDismissed: () {
                            setState(() {
                              _displayedMessage = null;
                              game.clearMessage();
                            });
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
