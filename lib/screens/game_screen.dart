// lib/screens/game_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'dart:async';
import '../game/shooting_game.dart';
import 'level_selection_screen.dart';

class GameScreen extends StatefulWidget {
  final int? levelId;
  final bool isLevelMode;

  GameScreen({
    this.levelId,
    required this.isLevelMode,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late ShootingGame game;
  bool isPaused = false;
  Key gameKey = UniqueKey();
  Timer? _uiUpdateTimer;
  bool _gameInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    WidgetsBinding.instance.addObserver(this);

    // Start UI update timer for level progress
    _startUIUpdateTimer();
  }

  void _initializeGame() {
    final topPadding = WidgetsBinding.instance.window.padding.top /
        WidgetsBinding.instance.window.devicePixelRatio;
    game = ShootingGame(safeAreaTop: topPadding);
  }

  void _startUIUpdateTimer() {
    // Update UI every 100ms for smooth progress bar and timer updates
    _uiUpdateTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (mounted && !isPaused) {
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

    // Wait a frame to ensure game is fully loaded
    await Future.delayed(Duration(milliseconds: 100));

    if (widget.isLevelMode && widget.levelId != null) {
      // Load specific level
      await game.loadAndStartLevel(widget.levelId!);
    } else if (!widget.isLevelMode) {
      // Start free play mode
      game.setLevelMode(false);
    }
  }

  void _togglePause() {
    if (isPaused) {
      _resumeGame();
    } else {
      _pauseGame();
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
        content: Text(
          'Are you sure you want to restart?',
          style: TextStyle(color: Colors.grey[300]),
        ),
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LevelSelectionScreen()),
                );
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    game.safeAreaTop = topPadding;

    return Scaffold(
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
      body: FutureBuilder(
          future: _initializeGameMode(),
          builder: (context, snapshot) {
            return Stack(
              children: [
                // Game widget
                GameWidget(
                  key: gameKey,
                  game: game,
                ),

                // Game controls overlay
                Positioned(
                  top: 15,
                  right: 20,
                  child: Column(
                    children: [
                      // Pause/Resume button
                      Container(
                        width: 50,
                        height: 50,
                        child: FloatingActionButton(
                          heroTag: "pause_button", // Add unique hero tag
                          onPressed: _togglePause,
                          backgroundColor: Colors.black.withOpacity(0.7),
                          child: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                            size: 24,
                          ),
                          mini: true,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Menu button
                      Container(
                        width: 50,
                        height: 50,
                        child: FloatingActionButton(
                          heroTag: "menu_button", // Add unique hero tag
                          onPressed: _showGameMenu,
                          backgroundColor: Colors.black.withOpacity(0.7),
                          child: Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                          mini: true,
                        ),
                      ),
                    ],
                  ),
                ),

                // Level info overlay (only in level mode)
                if (widget.isLevelMode && game.isLevelActive)
                  Positioned(
                    top: 80,
                    left: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.currentLevelName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (game.levelTimeRemaining.isNotEmpty)
                            Text(
                              '${game.levelTimeRemaining}s left',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Level progress bar (only in level mode)
                if (widget.isLevelMode && game.isLevelActive)
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: game.levelProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
      ),
    );
  }
}