class LevelEvent {
  final double timestamp;
  final String type;
  final double? spawnX; // Optional: 0.0-1.0 percentage of road width
  final Map<String, dynamic> parameters;

  LevelEvent({
    required this.timestamp,
    required this.type,
    this.spawnX,
    required this.parameters,
  });

  factory LevelEvent.fromJson(Map<String, dynamic> json) {
    final parameters = Map<String, dynamic>.from(json);
    parameters.remove('timestamp');
    parameters.remove('type');
    parameters.remove('spawn_x');

    return LevelEvent(
      timestamp: (json['timestamp'] as num).toDouble(),
      type: json['type'] as String,
      spawnX: json['spawn_x'] != null ? (json['spawn_x'] as num).toDouble() : null,
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
}
