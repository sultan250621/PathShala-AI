import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
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

  /// Seeds or updates questions in SQLite from a list of [QuestionModel]s.
  ///
  /// Re-seeds whenever [dataVersion] increases (or if [force] is true).
  /// Guarantees:
  /// - Prevents duplicate rows.
  /// - Preserves existing question IDs to ensure existing progress data and answer logs
  ///   tied to old question IDs are never lost or orphaned.
  /// - Records the updated dataVersion in the metadata table.
  static Future<bool> seedQuestions({
    required List<QuestionModel> questions,
    required int dataVersion,
    Database? database,
    bool force = false,
  }) async {
    final db = database ?? await DBHelper.getDatabase();

    // 1. Check stored data_version from metadata table
    final List<Map<String, dynamic>> metadata = await db.query(
      AppConstants.metadataTable,
      where: 'key = ?',
      whereArgs: [AppConstants.keyQuestionBankDataVersion],
    );

    int currentVersion = 0;
    if (metadata.isNotEmpty) {
      currentVersion = int.tryParse(metadata.first['value']?.toString() ?? '0') ?? 0;
    }

    // 2. Only re-seed if dataVersion increased or force flag is true
    if (!force && metadata.isNotEmpty && currentVersion >= dataVersion) {
      return false; // Already up to date
    }

    // 3. Batch re-seed while preserving existing question IDs and preventing duplicates
    await db.transaction((txn) async {
      // Fetch existing questions
      final existingRows = await txn.query(
        AppConstants.questionsTable,
        columns: ['id', 'class_level', 'topic', 'question_text'],
      );

      final Map<String, int> existingMap = {};
      for (final row in existingRows) {
        final id = row['id'] as int;
        final cLevel = row['class_level'] as int? ?? AppConstants.defaultClassLevel;
        final topic = (row['topic'] as String? ?? '').trim();
        final qText = (row['question_text'] as String? ?? '').trim();
        final key = '${cLevel}_${topic}_$qText';
        existingMap[key] = id;
      }

      final batch = txn.batch();
      for (final q in questions) {
        final key = '${q.classLevel}_${q.topic.trim()}_${q.questionText.trim()}';

        if (existingMap.containsKey(key)) {
          final existingId = existingMap[key]!;
          if (existingId > 0) {
            // Update existing question while strictly keeping its existing ID
            final updateMap = q.toMap()
              ..['id'] = existingId
              ..['hint'] = q.hint
              ..['explanation'] = q.explanation;
            batch.update(
              AppConstants.questionsTable,
              updateMap,
              where: 'id = ?',
              whereArgs: [existingId],
            );
          }
        } else {
          // New question: insert without specifying id so AUTOINCREMENT gives a new ID
          final insertMap = q.toMap()..remove('id');
          batch.insert(
            AppConstants.questionsTable,
            insertMap,
          );
          // Mark as seen so duplicates within the batch don't insert twice
          existingMap[key] = -1;
        }
      }

      await batch.commit(noResult: true);

      // Record updated versions in metadata table
      await txn.insert(
        AppConstants.metadataTable,
        {
          'key': AppConstants.keyQuestionBankDataVersion,
          'value': dataVersion.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        AppConstants.metadataTable,
        {
          'key': AppConstants.keyQuestionBankVersion,
          'value': dataVersion.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return true;
  }

  /// Loads questions from JSON asset or raw JSON string, and seeds into SQLite.
  /// Re-seeds if [data_version] has increased or if [force] is true.
  /// Preserves existing question IDs to protect progress data, and avoids duplicate rows.
  static Future<bool> seedQuestionBank({
    String assetPath = AppConstants.questionBankAsset,
    String? jsonContent,
    Database? database,
    bool force = false,
  }) async {
    final String rawJson = jsonContent ?? await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

    final int jsonVersion = (data['data_version'] as int?) ??
        (data['version'] as int?) ??
        1;
    final List<dynamic> questionsList = data['questions'] as List<dynamic>? ?? [];

    final questions = questionsList
        .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return seedQuestions(
      questions: questions,
      dataVersion: jsonVersion,
      database: database,
      force: force,
    );
  }
}
