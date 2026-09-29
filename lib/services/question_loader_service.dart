import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../models/question_model.dart';

/// Service responsible for loading question bank JSON and seeding SQLite database.
class QuestionLoaderService {
  /// Loads question bank from asset bundle and seeds database if version increased.
  /// Set [force] to true to force seeding regardless of version.
  static Future<bool> seedQuestionBank({
    String assetPath = AppConstants.questionBankAsset,
    String? jsonContent,
    Database? database,
    bool force = false,
  }) async {
    final db = database ?? await DBHelper.getDatabase();

    // 1. Read JSON content
    final String rawJson = jsonContent ?? await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

    final int jsonVersion = data['version'] as int? ?? 1;
    final List<dynamic> questionsList = data['questions'] as List<dynamic>? ?? [];

    // 2. Check stored version in database
    final List<Map<String, dynamic>> metadata = await db.query(
      AppConstants.metadataTable,
      where: 'key = ?',
      whereArgs: [AppConstants.keyQuestionBankVersion],
    );

    int currentVersion = 0;
    if (metadata.isNotEmpty) {
      currentVersion = int.tryParse(metadata.first['value']?.toString() ?? '0') ?? 0;
    }

    // 3. Only seed if version increased or force flag is true
    if (!force && metadata.isNotEmpty && currentVersion >= jsonVersion) {
      return false; // Already up to date
    }

    // 4. Batch insert in a single transaction
    await db.transaction((txn) async {
      // Clear previous questions on version upgrade to avoid duplicate rows
      await txn.delete(AppConstants.questionsTable);

      final batch = txn.batch();
      for (final item in questionsList) {
        final q = QuestionModel.fromJson(item as Map<String, dynamic>);
        batch.insert(
          AppConstants.questionsTable,
          q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      // Record new version in metadata table
      await txn.insert(
        AppConstants.metadataTable,
        {
          'key': AppConstants.keyQuestionBankVersion,
          'value': jsonVersion.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    return true;
  }
}
