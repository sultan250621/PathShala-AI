import 'dart:convert';
import 'dart:io';

/// Result summary of a chapter merge operation.
class MergeResult {
  final int oldVersion;
  final int newVersion;
  final int existingCount;
  final int incomingCount;
  final int addedCount;
  final int skippedCount;
  final int totalCount;
  final String targetPath;
  final String chapterPath;

  const MergeResult({
    required this.oldVersion,
    required this.newVersion,
    required this.existingCount,
    required this.incomingCount,
    required this.addedCount,
    required this.skippedCount,
    required this.totalCount,
    required this.targetPath,
    required this.chapterPath,
  });

  @override
  String toString() {
    return '''
==================================================
PathShala AI Question Bank Merge Summary
==================================================
Target File:       $targetPath
Chapter File:      $chapterPath
Data Version:      $oldVersion -> $newVersion (bumped +1)
Existing in Bank:  $existingCount
Incoming Chapter:  $incomingCount
Questions Added:   $addedCount
Skipped (Dupes):   $skippedCount
Total Bank Count:  $totalCount
==================================================''';
  }
}

/// Service and utility to merge chapter question files into the main question bank.
class QuestionBankMerger {
  static const String defaultTargetPath = 'assets/data/nctb_math_questions.json';

  /// Generates a deduplication key for a question map.
  static String buildQuestionKey(dynamic q) {
    if (q is Map) {
      final cLevel = q['class_level']?.toString() ?? '6';
      final topic = (q['topic']?.toString() ?? '').trim();
      final text = (q['question_text']?.toString() ?? q['question']?.toString() ?? '').trim();
      final optA = (q['option_a']?.toString() ?? '').trim();
      final optB = (q['option_b']?.toString() ?? '').trim();
      final optC = (q['option_c']?.toString() ?? '').trim();
      final optD = (q['option_d']?.toString() ?? '').trim();
      return '${cLevel}_${topic}_${text}_${optA}_${optB}_${optC}_${optD}';
    }
    return '';
  }

  /// Merges questions from [chapterPath] into [targetPath].
  ///
  /// - Reads questions from [chapterPath].
  /// - Appends questions not already present in [targetPath] (never overwriting existing ones).
  /// - Bumps `data_version` by 1.
  /// - Saves formatted UTF-8 JSON back to [targetPath].
  static Future<MergeResult> mergeChapterFile({
    required String chapterPath,
    String targetPath = defaultTargetPath,
    bool forceBump = true,
  }) async {
    final chapterFile = File(chapterPath);
    if (!await chapterFile.exists()) {
      throw FileSystemException('Chapter file not found', chapterPath);
    }

    final chapterRaw = await chapterFile.readAsString(encoding: utf8);
    final dynamic chapterParsed = jsonDecode(chapterRaw);

    List<dynamic> incomingQuestions;
    if (chapterParsed is Map<String, dynamic> && chapterParsed.containsKey('questions')) {
      incomingQuestions = chapterParsed['questions'] as List<dynamic>? ?? [];
    } else if (chapterParsed is List<dynamic>) {
      incomingQuestions = chapterParsed;
    } else {
      throw const FormatException(
        'Invalid chapter JSON: expected an object with a "questions" array or an array of questions.',
      );
    }

    final targetFile = File(targetPath);
    Map<String, dynamic> targetData;
    int oldVersion = 1;

    if (await targetFile.exists()) {
      final targetRaw = await targetFile.readAsString(encoding: utf8);
      targetData = jsonDecode(targetRaw) as Map<String, dynamic>;
      oldVersion = (targetData['data_version'] as int?) ??
          (targetData['version'] as int?) ??
          1;
    } else {
      targetData = {
        'data_version': 1,
        'questions': <dynamic>[],
      };
      oldVersion = 0;
    }

    final List<dynamic> existingQuestions =
        List<dynamic>.from(targetData['questions'] as List<dynamic>? ?? []);
    final int existingCount = existingQuestions.length;

    // Build deduplication index
    final Set<String> existingKeys = {};
    for (final q in existingQuestions) {
      final key = buildQuestionKey(q);
      if (key.isNotEmpty) {
        existingKeys.add(key);
      }
    }

    int addedCount = 0;
    int skippedCount = 0;

    for (final rawItem in incomingQuestions) {
      if (rawItem is! Map<String, dynamic> && rawItem is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(rawItem as Map);
      final key = buildQuestionKey(item);

      if (key.isNotEmpty && existingKeys.contains(key)) {
        skippedCount++;
      } else {
        // Normalize fields to ensure schema consistency
        final normalized = <String, dynamic>{
          'class_level': int.tryParse(item['class_level']?.toString() ?? '6') ?? 6,
          'topic': item['topic']?.toString().trim() ?? '',
          'difficulty': _parseDifficulty(item['difficulty']),
          'question_text': (item['question_text'] ?? item['question'])?.toString().trim() ?? '',
          'option_a': item['option_a']?.toString().trim() ?? '',
          'option_b': item['option_b']?.toString().trim() ?? '',
          'option_c': item['option_c']?.toString().trim() ?? '',
          'option_d': item['option_d']?.toString().trim() ?? '',
          'correct_option': (item['correct_option'] ?? item['correct_answer'])?.toString().trim().toUpperCase() ?? 'A',
          'hint': item['hint']?.toString().trim(),
          'explanation': item['explanation']?.toString().trim(),
        };

        existingQuestions.add(normalized);
        if (key.isNotEmpty) {
          existingKeys.add(key);
        }
        addedCount++;
      }
    }

    // Bump data_version by 1
    final newVersion = (forceBump || addedCount > 0) ? (oldVersion + 1) : oldVersion;
    targetData['data_version'] = newVersion;
    targetData.remove('version'); // remove legacy 'version' key if present
    targetData['questions'] = existingQuestions;

    // Ensure parent directory exists
    final parentDir = targetFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    // Write formatted JSON with 2-space indentation and UTF-8 encoding
    const encoder = JsonEncoder.withIndent('  ');
    final formattedJson = '${encoder.convert(targetData)}\n';
    await targetFile.writeAsString(formattedJson, encoding: utf8);

    return MergeResult(
      oldVersion: oldVersion,
      newVersion: newVersion,
      existingCount: existingCount,
      incomingCount: incomingQuestions.length,
      addedCount: addedCount,
      skippedCount: skippedCount,
      totalCount: existingQuestions.length,
      targetPath: targetPath,
      chapterPath: chapterPath,
    );
  }

  static int _parseDifficulty(dynamic diff) {
    if (diff is int) return diff;
    if (diff is String) {
      final s = diff.toLowerCase();
      if (s == 'easy' || s == '1') return 1;
      if (s == 'medium' || s == '2') return 2;
      if (s == 'hard' || s == '3') return 3;
      return int.tryParse(s) ?? 1;
    }
    return 1;
  }
}
