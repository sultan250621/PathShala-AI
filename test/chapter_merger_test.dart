import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapps/services/question_bank_merger.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('merge_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('QuestionBankMerger merges new chapter and bumps data_version', () async {
    final targetFile = File('${tempDir.path}/test_bank.json');
    final chapterFile = File('${tempDir.path}/chapter_1.json');

    // Initial question bank with version 1 and 1 question
    await targetFile.writeAsString(jsonEncode({
      'data_version': 1,
      'questions': [
        {
          'class_level': 6,
          'topic': 'Fractions',
          'difficulty': 1,
          'question_text': 'What is 1/2 + 1/4?',
          'option_a': '3/4',
          'option_b': '2/6',
          'option_c': '1/6',
          'option_d': '2/4',
          'correct_option': 'A',
          'hint': 'Find common denominator',
          'explanation': '1/2 = 2/4',
        }
      ]
    }), encoding: utf8);

    // Chapter 1 has 1 existing question and 1 new question
    await chapterFile.writeAsString(jsonEncode({
      'questions': [
        {
          'class_level': 6,
          'topic': 'Fractions',
          'difficulty': 1,
          'question_text': 'What is 1/2 + 1/4?', // Duplicate
          'option_a': '3/4',
          'option_b': '2/6',
          'option_c': '1/6',
          'option_d': '2/4',
          'correct_option': 'A',
          'hint': 'Find common denominator',
          'explanation': '1/2 = 2/4',
        },
        {
          'class_level': 6,
          'topic': 'Algebra',
          'difficulty': 2,
          'question_text': 'Solve 2x = 10',
          'option_a': 'x = 5',
          'option_b': 'x = 8',
          'option_c': 'x = 20',
          'option_d': 'x = 2',
          'correct_option': 'A',
          'hint': 'Divide by 2',
          'explanation': 'x = 10 / 2 = 5',
        }
      ]
    }), encoding: utf8);

    final result = await QuestionBankMerger.mergeChapterFile(
      chapterPath: chapterFile.path,
      targetPath: targetFile.path,
    );

    expect(result.oldVersion, equals(1));
    expect(result.newVersion, equals(2));
    expect(result.existingCount, equals(1));
    expect(result.incomingCount, equals(2));
    expect(result.addedCount, equals(1));
    expect(result.skippedCount, equals(1));
    expect(result.totalCount, equals(2));

    // Verify written file
    final writtenData = jsonDecode(await targetFile.readAsString(encoding: utf8)) as Map<String, dynamic>;
    expect(writtenData['data_version'], equals(2));
    final questions = writtenData['questions'] as List;
    expect(questions.length, equals(2));
    expect(questions[1]['question_text'], equals('Solve 2x = 10'));
  });

  test('QuestionBankMerger handles merging into an empty bank and prevents duplicates', () async {
    final targetFile = File('${tempDir.path}/nctb_math_questions_test.json');
    final chapterFile = File('${tempDir.path}/chapter_sample.json');

    await chapterFile.writeAsString(
      jsonEncode({
        'questions': List.generate(
          10,
          (i) => {
            'class_level': 6,
            'topic': 'Fractions',
            'difficulty': 1,
            'question_text': 'Sample Question $i',
            'option_a': 'A',
            'option_b': 'B',
            'option_c': 'C',
            'option_d': 'D',
            'correct_option': 'A',
            'hint': 'Hint $i',
            'explanation': 'Explanation $i',
          },
        ),
      }),
      encoding: utf8,
    );

    // Initial empty target
    final result = await QuestionBankMerger.mergeChapterFile(
      chapterPath: chapterFile.path,
      targetPath: targetFile.path,
    );

    expect(result.addedCount, equals(10));
    expect(result.totalCount, equals(10));
    expect(result.newVersion, equals(1));

    // Merging again should detect all 10 as duplicates and not increase count
    final secondMerge = await QuestionBankMerger.mergeChapterFile(
      chapterPath: chapterFile.path,
      targetPath: targetFile.path,
      forceBump: false,
    );

    expect(secondMerge.addedCount, equals(0));
    expect(secondMerge.skippedCount, equals(10));
    expect(secondMerge.totalCount, equals(10));
  });
}
