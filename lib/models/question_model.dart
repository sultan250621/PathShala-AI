/// Model representing a curriculum-aligned question entity.
class QuestionModel {
  final int? id;
  final int classLevel;
  final String subject;
  final String topic;
  final int difficulty;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption; // 'A', 'B', 'C', or 'D'
  final String? hint;
  final String? explanation;

  const QuestionModel({
    this.id,
    this.classLevel = 6,
    this.subject = 'Mathematics',
    required this.topic,
    required this.difficulty,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.hint,
    this.explanation,
  });

  /// Map of option letter to its display text.
  Map<String, String> get options => {
        'A': optionA,
        'B': optionB,
        'C': optionC,
        'D': optionD,
      };

  /// Text corresponding to the correct option letter.
  String get correctOptionText => options[correctOption] ?? '';

  /// Backward-compatible alias for correct option text.
  String get correctAnswer => correctOptionText;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'class_level': classLevel,
      'subject': subject,
      'topic': topic,
      'difficulty': difficulty,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      if (hint != null) 'hint': hint,
      if (explanation != null) 'explanation': explanation,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    // Handle integer or string difficulty gracefully
    int parsedDifficulty = 1;
    if (map['difficulty'] is int) {
      parsedDifficulty = map['difficulty'] as int;
    } else if (map['difficulty'] is String) {
      if (map['difficulty'] == 'medium' || map['difficulty'] == '2') {
        parsedDifficulty = 2;
      } else if (map['difficulty'] == 'hard' || map['difficulty'] == '3') {
        parsedDifficulty = 3;
      }
    }

    return QuestionModel(
      id: map['id'] as int?,
      classLevel: map['class_level'] as int? ?? 6,
      subject: map['subject'] as String? ?? 'Mathematics',
      topic: map['topic'] as String? ?? '',
      difficulty: parsedDifficulty,
      questionText: (map['question_text'] ?? map['question']) as String? ?? '',
      optionA: map['option_a'] as String? ?? '',
      optionB: map['option_b'] as String? ?? '',
      optionC: map['option_c'] as String? ?? '',
      optionD: map['option_d'] as String? ?? '',
      correctOption: (map['correct_option'] ?? map['correct_answer']) as String? ?? 'A',
      hint: map['hint'] as String?,
      explanation: map['explanation'] as String?,
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel.fromMap(json);
  }
}
