/// Model representing student learning progress on a specific topic.
class ProgressModel {
  final String topic;
  final int correct;
  final int total;
  final bool isSynced;
  final DateTime? updatedAt;

  const ProgressModel({
    required this.topic,
    required this.correct,
    required this.total,
    this.isSynced = false,
    this.updatedAt,
  });

  double get masteryPercentage => total > 0 ? (correct / total) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'correct': correct,
      'total': total,
    };
  }

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      topic: map['topic'] as String? ?? '',
      correct: map['correct'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
    );
  }
}
