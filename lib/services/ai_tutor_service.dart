import '../models/question_model.dart';

/// Architectural foundation for On-Device Offline AI Tutoring.
/// (Foundation for Week 4 roadmap: offline hints and concept explanation).
class AITutorService {
  /// Generate a concise hint for a question without revealing the answer directly.
  static Future<String> generateHint(QuestionModel question) async {
    // If the question already has an authored hint, use it as fallback.
    if (question.hint != null && question.hint!.trim().isNotEmpty) {
      return question.hint!;
    }

    // Default pedagogical hint template for offline foundation
    return 'Tip: Carefully analyze the given options and break down the problem step by step.';
  }

  /// Generate a step-by-step conceptual explanation for a question.
  static Future<String> generateExplanation(QuestionModel question) async {
    if (question.explanation != null && question.explanation!.trim().isNotEmpty) {
      return question.explanation!;
    }

    return 'The correct answer is "${question.correctAnswer}". Review the core principles of ${question.topic}.';
  }
}
