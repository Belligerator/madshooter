import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _keyPrefix = 'level_stars_';

  static Future<int> getBestStars(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$levelId') ?? 0;
  }

  static Future<void> saveBestStars(int levelId, int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final currentBest = prefs.getInt('$_keyPrefix$levelId') ?? 0;
    if (stars > currentBest) {
      await prefs.setInt('$_keyPrefix$levelId', stars);
    }
  }

  static Future<Map<int, int>> getAllLevelStars() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<int, int> stars = {};
    // Support up to 100 levels
    for (int i = 1; i <= 100; i++) {
      final value = prefs.getInt('$_keyPrefix$i');
      if (value != null) {
        stars[i] = value;
      }
    }
    return stars;
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
