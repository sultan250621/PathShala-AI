import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../models/question_model.dart';
import 'db_helper.dart';

/// Data Access Object for Question operations.
class QuestionDao {
  /// Fetch all questions for a given topic and optional class level.
  static Future<List<QuestionModel>> getQuestionsByTopic(
    String topic, {
    int classLevel = AppConstants.defaultClassLevel,
    Database? database,
  }) async {
    final db = database ?? await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.questionsTable,
      where: 'topic = ? AND class_level = ?',
      whereArgs: [topic, classLevel],
    );

    return List.generate(maps.length, (i) => QuestionModel.fromMap(maps[i]));
  }

  /// Fetch questions filtered by topic, difficulty level (1/2/3), and class level.
  static Future<List<QuestionModel>> getQuestionsByDifficulty(
    String topic,
    int difficulty, {
    int classLevel = AppConstants.defaultClassLevel,
    Database? database,
  }) async {
    final db = database ?? await DBHelper.getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.questionsTable,
      where: 'topic = ? AND difficulty = ? AND class_level = ?',
      whereArgs: [topic, difficulty, classLevel],
    );

    return List.generate(maps.length, (i) => QuestionModel.fromMap(maps[i]));
  }

  /// List all distinct topics along with their total question counts.
  static Future<Map<String, int>> getTopicsWithCounts({
    int classLevel = AppConstants.defaultClassLevel,
    Database? database,
  }) async {
    final db = database ?? await DBHelper.getDatabase();
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT topic, COUNT(*) as count 
      FROM ${AppConstants.questionsTable} 
      WHERE class_level = ? 
      GROUP BY topic
      ORDER BY topic ASC
      ''',
      [classLevel],
    );

    final Map<String, int> topicCounts = {};
    for (final row in results) {
      final topic = row['topic'] as String? ?? '';
      final count = row['count'] as int? ?? 0;
      if (topic.isNotEmpty) {
        topicCounts[topic] = count;
      }
    }
    return topicCounts;
  }

  /// Randomly select questions for a topic with no repeats in a session.
  static Future<List<QuestionModel>> getRandomQuestions({
    required String topic,
    int count = 10,
    List<int> excludeIds = const [],
    int classLevel = AppConstants.defaultClassLevel,
    Database? database,
  }) async {
    final db = database ?? await DBHelper.getDatabase();

    String whereClause = 'topic = ? AND class_level = ?';
    List<dynamic> whereArgs = [topic, classLevel];

    if (excludeIds.isNotEmpty) {
      final placeholders = List.filled(excludeIds.length, '?').join(',');
      whereClause += ' AND id NOT IN ($placeholders)';
      whereArgs.addAll(excludeIds);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.questionsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'RANDOM()',
      limit: count,
    );

    return List.generate(maps.length, (i) => QuestionModel.fromMap(maps[i]));
  }

  /// Insert a single question into the local database.
  static Future<int> insertQuestion(QuestionModel question, {Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    return await db.insert(
      AppConstants.questionsTable,
      question.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch total question count across all topics.
  static Future<int> getTotalQuestionCount({
    int classLevel = AppConstants.defaultClassLevel,
    Database? database,
  }) async {
    final db = database ?? await DBHelper.getDatabase();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.questionsTable} WHERE class_level = ?',
      [classLevel],
    );
    if (result.isNotEmpty) {
      return result.first['count'] as int? ?? 0;
    }
    return 0;
  }
}
