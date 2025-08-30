// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait (optional)
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mad Shooter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainMenuScreen(),
    );
  }
}
