// lib/screens/level_selection_screen.dart

import 'package:flutter/material.dart';
import '../game/levels/level_data.dart';
import '../game/levels/level_manager.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  @override
  _LevelSelectionScreenState createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  List<LevelData> availableLevels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final levels = <LevelData>[];

    // Try to load levels 1-10 (expand as needed)
    for (int i = 1; i <= 10; i++) {
      final levelData = await LevelManager.loadLevelData(i);
      if (levelData != null) {
        levels.add(levelData);
      } else {
        // Level doesn't exist, stop loading
        break;
      }
    }

    setState(() {
      availableLevels = levels;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Select Level',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(color: Colors.blue),
      )
          : availableLevels.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'No levels found',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 8),
            Text(
              'Make sure level files are in assets/levels/',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      )
          : Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Free Play Mode Button
            _buildFreePlayCard(context),
            SizedBox(height: 16),

            // Level List Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Campaign Levels',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12),

            // Levels Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: availableLevels.length,
                itemBuilder: (context, index) {
                  return _buildLevelCard(context, availableLevels[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePlayCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 80,
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _startFreePlay(context),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.all_inclusive, color: Colors.green, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Free Play Mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Endless survival with random spawning',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow, color: Colors.green, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, LevelData level) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _startLevel(context, level.levelId),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Level header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Level ${level.levelId}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.timer, color: Colors.grey[400], size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${level.duration.toInt()}s',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Level name
              Text(
                level.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),

              // Description
              Text(
                level.description,
                style: TextStyle(color: Colors.grey[300], fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Spacer(),

              // Starting conditions
              _buildStartingConditions(level),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartingConditions(LevelData level) {
    final conditions = level.startingConditions;
    final items = <Widget>[];

    if (conditions.bulletSizeMultiplier > 1.0) {
      items.add(_buildConditionChip(
        '${conditions.bulletSizeMultiplier}x Size',
        Colors.brown,
      ));
    }

    if (conditions.additionalFireRate > 0) {
      items.add(_buildConditionChip(
        '+${conditions.additionalFireRate.toInt()}/s Rate',
        Colors.orange,
      ));
    }

    if (conditions.allyCount > 0) {
      items.add(_buildConditionChip(
        '${conditions.allyCount} ${conditions.allyCount == 1 ? 'Ally' : 'Allies'}',
        Colors.green,
      ));
    }

    if (items.isEmpty) {
      items.add(_buildConditionChip('Basic Start', Colors.grey));
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: items,
    );
  }

  Widget _buildConditionChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _startLevel(BuildContext context, int levelId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          levelId: levelId,
          isLevelMode: true,
        ),
      ),
    );
  }

  void _startFreePlay(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          isLevelMode: false,
        ),
      ),
    );
  }
}