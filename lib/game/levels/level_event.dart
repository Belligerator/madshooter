class LevelEvent {
  final double timestamp;
  final String type;
  final double? spawnX; // Optional: 0.0-1.0 percentage of road width
  final bool ignore; // If true, skip this event (for testing)
  final Map<String, dynamic> parameters;

  LevelEvent({
    required this.timestamp,
    required this.type,
    this.spawnX,
    this.ignore = false,
    required this.parameters,
  });

  factory LevelEvent.fromJson(Map<String, dynamic> json) {
    final parameters = Map<String, dynamic>.from(json);
    parameters.remove('timestamp');
    parameters.remove('type');
    parameters.remove('spawn_x');
    parameters.remove('ignore');

    return LevelEvent(
      timestamp: (json['timestamp'] as num).toDouble(),
      type: json['type'] as String,
      spawnX: json['spawn_x'] != null ? (json['spawn_x'] as num).toDouble() : null,
      ignore: json['ignore'] as bool? ?? false,
      parameters: parameters,
    );
  }

  Map<String, dynamic> toJson() {
    final result = Map<String, dynamic>.from(parameters);
    result['timestamp'] = timestamp;
    result['type'] = type;
    if (spawnX != null) {
      result['spawn_x'] = spawnX;
    }
    return result;
  }

  @override
  String toString() {
    return 'LevelEvent{timestamp: $timestamp, type: $type}';
  }
}
