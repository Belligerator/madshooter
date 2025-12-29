import 'package:flutter/material.dart';

class UpMeter extends StatelessWidget {
  final int currentPoints;
  final int maxPoints;

  const UpMeter({
    super.key,
    required this.currentPoints,
    this.maxPoints = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            // "UP" label at top
            Text(
              'UP',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            // Battery segments
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(maxPoints, (index) {
                  final segmentIndex = maxPoints - 1 - index;
                  final isFilled = segmentIndex < currentPoints;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: isFilled ? _getSegmentColor(segmentIndex) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: _getSegmentColor(segmentIndex).withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 4),
            // Count at bottom
            Text(
              '$currentPoints',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSegmentColor(int index) {
    // Gradient from green (bottom) to yellow (middle) to amber (top)
    if (index < 4) {
      return Colors.green;
    } else if (index < 7) {
      return Colors.yellow;
    } else {
      return Colors.amber;
    }
  }
}
