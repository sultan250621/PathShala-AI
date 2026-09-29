/// Application constants for the PathShala AI learning application.
class AppConstants {
  static const String appName = 'PathShala AI';
  static const String dbName = 'quiz_app.db';
  static const int dbVersion = 3;

  // Table Names
  static const String questionsTable = 'questions';
  static const String progressTable = 'progress';
  static const String answerLogsTable = 'answer_logs';
  static const String metadataTable = 'app_metadata';

  // Metadata Keys
  static const String keyQuestionBankVersion = 'question_bank_version';

  // Asset Paths
  static const String questionBankAsset = 'assets/data/nctb_math_questions.json';

  // Default Subject & Class
  static const String defaultSubject = 'Mathematics';
  static const int defaultClassLevel = 6;
  static const String defaultClassLabel = 'Class 6';

  // Fallback Topics (if empty)
  static const List<String> defaultTopics = [
    'স্বাভাবিক সংখ্যা ও ভগ্নাংশ (Fractions & Natural Numbers)',
    'বীজগণিতীয় রাশি (Algebraic Expressions)',
    'জ্যামিতির মৌলিক ধারণা (Basic Geometry)',
  ];

  // Difficulty numeric levels
  static const int difficultyEasy = 1;
  static const int difficultyMedium = 2;
  static const int difficultyHard = 3;

  // UI Target specifications
  static const double minTapTargetSize = 48.0;
  static const double cardBorderRadius = 16.0;
  static const double baseFontSize = 16.0;
}
