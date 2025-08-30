class LevelEvent {
  final double timestamp;
  final String type;
  final Map<String, dynamic> parameters;

  LevelEvent({required this.timestamp, required this.type, required this.parameters});

  factory LevelEvent.fromJson(Map<String, dynamic> json) {
    final parameters = Map<String, dynamic>.from(json);
    parameters.remove('timestamp');
    parameters.remove('type');

    return LevelEvent(
      timestamp: (json['timestamp'] as num).toDouble(),
      type: json['type'] as String,
      parameters: parameters,
    );
  }

  Map<String, dynamic> toJson() {
    final result = Map<String, dynamic>.from(parameters);
    result['timestamp'] = timestamp;
    result['type'] = type;
    return result;
  }
}
