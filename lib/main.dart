import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/shooting_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait (optional)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Shooting Game Prototype', debugShowCheckedModeBanner: false, home: GameScreen());
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late ShootingGame game;
  bool isPaused = false;
  Key gameKey = UniqueKey(); // Add this to force GameWidget recreation

  @override
  void initState() {
    super.initState();
    _initializeGame();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeGame() {
    final topPadding = WidgetsBinding.instance.window.padding.top / WidgetsBinding.instance.window.devicePixelRatio;
    game = ShootingGame(safeAreaTop: topPadding);
  }

  @override
  void dispose() {
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
        // _resumeGame();
        break;
      case AppLifecycleState.inactive:
        // Don't pause for inactive (e.g., notification pull-down)
        break;
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

  // Add reset functionality
  void _resetGame() {
    if (!isPaused) {
      _pauseGame();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restart Game?'),
        content: Text('Are you sure you want to restart the game?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              _resumeGame();
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss dialog
              setState(() {
                isPaused = false;
                gameKey = UniqueKey(); // Force GameWidget to recreate
                _initializeGame(); // Create new game instance
              });
            },
            child: Text('Yes'),
          ),
        ],
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
        toolbarHeight: 0, // No visible app bar, just handles safe area
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Stack(
        children: [
          // Game widget with unique key to force recreation
          GameWidget(
            key: gameKey, // This forces the widget to recreate when key changes
            game: game,
          ),
          // Pause button overlay
          Positioned(
            top: 15,
            right: 20,
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: _togglePause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(60, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: Text(isPaused ? '▶️' : '⏸️', style: TextStyle(fontSize: 16)),
                  ),
                ),
                Container(
                  width: 60,
                  height: 30,
                  child: ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: Size(60, 30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: Text('🔄', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          // Add reset button

        ],
      ),
    );
  }
}
