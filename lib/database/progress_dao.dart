import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../models/progress_model.dart';
import 'db_helper.dart';

/// Data Access Object for Student Progress and Answer Logging operations.
class ProgressDao {
  /// Record a single quiz answer and update topic-level summary progress.
  static Future<void> saveAnswer({
    required String topic,
    required int difficulty,
    required bool isCorrect,
    DateTime? timestamp,
    Database? database,
  }) async {
    final db = database ?? await DBHelper.getDatabase();
    final timeStr = (timestamp ?? DateTime.now()).toIso8601String();

    await db.transaction((txn) async {
      // 1. Log individual answer
      await txn.insert(AppConstants.answerLogsTable, {
        'topic': topic,
        'difficulty': difficulty,
        'is_correct': isCorrect ? 1 : 0,
        'timestamp': timeStr,
      });

      // 2. Update progress summary table
      final existing = await txn.query(
        AppConstants.progressTable,
        where: 'topic = ?',
        whereArgs: [topic],
      );

      if (existing.isEmpty) {
        await txn.insert(AppConstants.progressTable, {
          'topic': topic,
          'correct': isCorrect ? 1 : 0,
          'total': 1,
          'is_synced': 0,
          'updated_at': timeStr,
        });
      } else {
        final currentCorrect = existing.first['correct'] as int? ?? 0;
        final currentTotal = existing.first['total'] as int? ?? 0;
        await txn.update(
          AppConstants.progressTable,
          {
            'correct': currentCorrect + (isCorrect ? 1 : 0),
            'total': currentTotal + 1,
            'is_synced': 0,
            'updated_at': timeStr,
          },
          where: 'topic = ?',
          whereArgs: [topic],
        );
      }
    });
  }

  /// Retrieve accuracy (0.0 to 1.0) for a given topic.
  static Future<double> getTopicAccuracy(String topic, {Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    final rows = await db.query(
      AppConstants.progressTable,
      where: 'topic = ?',
      whereArgs: [topic],
    );

    if (rows.isEmpty) return 0.0;
    final correct = rows.first['correct'] as int? ?? 0;
    final total = rows.first['total'] as int? ?? 0;
    return total > 0 ? (correct / total) : 0.0;
  }

  /// Retrieve topic-wise accuracy mapping for all topics.
  static Future<Map<String, double>> getAllTopicAccuracies({Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    final rows = await db.query(AppConstants.progressTable);

    final Map<String, double> accuracies = {};
    for (final row in rows) {
      final topic = row['topic'] as String? ?? '';
      final correct = row['correct'] as int? ?? 0;
      final total = row['total'] as int? ?? 0;
      if (topic.isNotEmpty) {
        accuracies[topic] = total > 0 ? (correct / total) : 0.0;
      }
    }
    return accuracies;
  }

  /// Retrieve full progress models for all recorded topics.
  static Future<Map<String, ProgressModel>> getAllProgressModels({Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    final rows = await db.query(AppConstants.progressTable);

    final Map<String, ProgressModel> progressMap = {};
    for (final row in rows) {
      final model = ProgressModel.fromMap(row);
      progressMap[model.topic] = model;
    }
    return progressMap;
  }

  /// Retrieve overall accuracy across all topics combined.
  static Future<double> getOverallAccuracy({Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    final result = await db.rawQuery(
      'SELECT SUM(correct) as total_correct, SUM(total) as total_attempts FROM ${AppConstants.progressTable}',
    );

    if (result.isNotEmpty) {
      final totalCorrect = result.first['total_correct'] as int? ?? 0;
      final totalAttempts = result.first['total_attempts'] as int? ?? 0;
      return totalAttempts > 0 ? (totalCorrect / totalAttempts) : 0.0;
    }
    return 0.0;
  }

  /// Legacy helper to update batch progress.
  static Future<void> updateProgress(String topic, int correct, int total, {Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    final existing = await db.query(
      AppConstants.progressTable,
      where: 'topic = ?',
      whereArgs: [topic],
    );

    final now = DateTime.now().toIso8601String();
    if (existing.isEmpty) {
      await db.insert(
        AppConstants.progressTable,
        {
          'topic': topic,
          'correct': correct,
          'total': total,
          'is_synced': 0,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      final oldCorrect = existing.first['correct'] as int? ?? 0;
      final oldTotal = existing.first['total'] as int? ?? 0;
      await db.update(
        AppConstants.progressTable,
        {
          'correct': oldCorrect + correct,
          'total': oldTotal + total,
          'is_synced': 0,
          'updated_at': now,
        },
        where: 'topic = ?',
        whereArgs: [topic],
      );
    }
  }

  /// Legacy helper to retrieve mapped progress.
  static Future<Map<String, double>> getAllProgress(List<String> topics, {Database? database}) async {
    final accuracies = await getAllTopicAccuracies(database: database);
    final Map<String, double> result = {for (var t in topics) t: 0.0};
    accuracies.forEach((topic, acc) {
      result[topic] = acc;
    });
    return result;
  }

  /// Retrieve unsynced progress entries.
  static Future<List<ProgressModel>> getUnsyncedProgress({Database? database}) async {
    final db = database ?? await DBHelper.getDatabase();
    final rows = await db.query(
      AppConstants.progressTable,
      where: 'is_synced = ?',
      whereArgs: [0],
    );
    return rows.map((r) => ProgressModel.fromMap(r)).toList();
  }

  /// Mark synced topics.
  static Future<void> markAsSynced(List<String> topics, {Database? database}) async {
    if (topics.isEmpty) return;
    final db = database ?? await DBHelper.getDatabase();
    final batch = db.batch();
    for (final topic in topics) {
      batch.update(
        AppConstants.progressTable,
        {'is_synced': 1},
        where: 'topic = ?',
        whereArgs: [topic],
      );
    }
    await batch.commit(noResult: true);
  }
}
