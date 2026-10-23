import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobileapps/constants/app_constants.dart';
import 'package:mobileapps/database/progress_dao.dart';
import 'package:mobileapps/database/question_dao.dart';
import 'package:mobileapps/services/question_loader_service.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;

  const sampleJsonContent = '''
  {
    "version": 1,
    "questions": [
      {
        "class_level": 6,
        "topic": "Fractions",
        "difficulty": 1,
        "question_text": "What is 1/2 + 1/4?",
        "option_a": "3/4",
        "option_b": "2/6",
        "option_c": "1/6",
        "option_d": "2/4",
        "correct_option": "A",
        "hint": "Find common denominator",
        "explanation": "1/2 = 2/4, 2/4 + 1/4 = 3/4"
      },
      {
        "class_level": 6,
        "topic": "Fractions",
        "difficulty": 2,
        "question_text": "What is 2/3 x 3/4?",
        "option_a": "1/2",
        "option_b": "6/7",
        "option_c": "5/7",
        "option_d": "2/4",
        "correct_option": "A",
        "hint": "Multiply numerators and denominators",
        "explanation": "6/12 simplifies to 1/2"
      },
      {
        "class_level": 6,
        "topic": "Algebra",
        "difficulty": 1,
        "question_text": "Solve x + 5 = 12",
        "option_a": "x = 7",
        "option_b": "x = 17",
        "option_c": "x = 5",
        "option_d": "x = 12",
        "correct_option": "A",
        "hint": "Subtract 5 from 12",
        "explanation": "x = 12 - 5 = 7"
      },
      {
        "class_level": 6,
        "topic": "Algebra",
        "difficulty": 3,
        "question_text": "If x = 3, what is 2x^2 + 4?",
        "option_a": "22",
        "option_b": "40",
        "option_c": "16",
        "option_d": "10",
        "correct_option": "A",
        "hint": "Calculate 3^2 first",
        "explanation": "2(9) + 4 = 22"
      }
    ]
  }
  ''';

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    // Create tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.questionsTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_level INTEGER NOT NULL DEFAULT 6,
        subject TEXT NOT NULL DEFAULT 'Mathematics',
        topic TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_option TEXT NOT NULL,
        hint TEXT,
        explanation TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.metadataTable}(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.progressTable}(
        topic TEXT PRIMARY KEY,
        correct INTEGER NOT NULL DEFAULT 0,
        total INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.answerLogsTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  });

  tearDown(() async {
    await db.close();
  });

  group('QuestionDao and Loader Unit Tests', () {
    test('QuestionLoaderService seeds questions and prevents duplicate seeding', () async {
      // First seed
      final seededFirst = await QuestionLoaderService.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );
      expect(seededFirst, isTrue);

      final countFirst = await QuestionDao.getTotalQuestionCount(database: db);
      expect(countFirst, equals(4));

      // Attempt second seed with same version (should skip and not duplicate)
      final seededSecond = await QuestionLoaderService.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );
      expect(seededSecond, isFalse);

      final countSecond = await QuestionDao.getTotalQuestionCount(database: db);
      expect(countSecond, equals(4)); // Still 4, no duplicates
    });

    test('QuestionDao filters questions by topic', () async {
      await QuestionLoaderService.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );

      final fractionQuestions = await QuestionDao.getQuestionsByTopic('Fractions', database: db);
      expect(fractionQuestions.length, equals(2));
      expect(fractionQuestions.every((q) => q.topic == 'Fractions'), isTrue);

      final algebraQuestions = await QuestionDao.getQuestionsByTopic('Algebra', database: db);
      expect(algebraQuestions.length, equals(2));
      expect(algebraQuestions.every((q) => q.topic == 'Algebra'), isTrue);
    });

    test('QuestionDao filters questions by topic and difficulty', () async {
      await QuestionLoaderService.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );

      final easyFractions = await QuestionDao.getQuestionsByDifficulty(
        'Fractions',
        1,
        database: db,
      );
      expect(easyFractions.length, equals(1));
      expect(easyFractions.first.difficulty, equals(1));
      expect(easyFractions.first.questionText, contains('1/2 + 1/4'));

      final hardAlgebra = await QuestionDao.getQuestionsByDifficulty(
        'Algebra',
        3,
        database: db,
      );
      expect(hardAlgebra.length, equals(1));
      expect(hardAlgebra.first.difficulty, equals(3));
      expect(hardAlgebra.first.questionText, contains('2x^2 + 4'));
    });

    test('QuestionDao getTopicsWithCounts returns correct counts per topic', () async {
      await QuestionLoaderService.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );

      final topicCounts = await QuestionDao.getTopicsWithCounts(database: db);
      expect(topicCounts['Fractions'], equals(2));
      expect(topicCounts['Algebra'], equals(2));
      expect(topicCounts.length, equals(2));
    });

    test('QuestionDao getRandomQuestions returns non-repeating questions', () async {
      await QuestionLoaderService.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );

      final randomQuestions = await QuestionDao.getRandomQuestions(
        topic: 'Fractions',
        count: 2,
        database: db,
      );
      expect(randomQuestions.length, equals(2));
      expect(randomQuestions[0].id != randomQuestions[1].id, isTrue);
    });

    test('QuestionDao re-seeds when data_version increases and preserves existing question IDs', () async {
      // Seed version 1
      final seededV1 = await QuestionDao.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );
      expect(seededV1, isTrue);

      final initialQuestions = await QuestionDao.getQuestionsByTopic('Fractions', database: db);
      expect(initialQuestions.length, equals(2));
      final originalId1 = initialQuestions[0].id;
      final originalId2 = initialQuestions[1].id;
      expect(originalId1, isNotNull);
      expect(originalId2, isNotNull);

      // New chapter content with data_version: 2, containing the original questions plus 1 new question
      const version2JsonContent = '''
      {
        "data_version": 2,
        "questions": [
          {
            "class_level": 6,
            "topic": "Fractions",
            "difficulty": 1,
            "question_text": "What is 1/2 + 1/4?",
            "option_a": "3/4",
            "option_b": "2/6",
            "option_c": "1/6",
            "option_d": "2/4",
            "correct_option": "A",
            "hint": "Find common denominator",
            "explanation": "1/2 = 2/4, 2/4 + 1/4 = 3/4"
          },
          {
            "class_level": 6,
            "topic": "Fractions",
            "difficulty": 2,
            "question_text": "What is 2/3 x 3/4?",
            "option_a": "1/2",
            "option_b": "6/7",
            "option_c": "5/7",
            "option_d": "2/4",
            "correct_option": "A",
            "hint": "Multiply numerators and denominators",
            "explanation": "6/12 simplifies to 1/2"
          },
          {
            "class_level": 6,
            "topic": "Algebra",
            "difficulty": 1,
            "question_text": "Solve x + 5 = 12",
            "option_a": "x = 7",
            "option_b": "x = 17",
            "option_c": "x = 5",
            "option_d": "x = 12",
            "correct_option": "A",
            "hint": "Subtract 5 from 12",
            "explanation": "x = 12 - 5 = 7"
          },
          {
            "class_level": 6,
            "topic": "Algebra",
            "difficulty": 3,
            "question_text": "If x = 3, what is 2x^2 + 4?",
            "option_a": "22",
            "option_b": "40",
            "option_c": "16",
            "option_d": "10",
            "correct_option": "A",
            "hint": "Calculate 3^2 first",
            "explanation": "2(9) + 4 = 22"
          },
          {
            "class_level": 6,
            "topic": "Fractions",
            "difficulty": 3,
            "question_text": "What is 3/4 divided by 1/2?",
            "option_a": "3/2",
            "option_b": "3/8",
            "option_c": "1/2",
            "option_d": "2/3",
            "correct_option": "A",
            "hint": "Invert and multiply",
            "explanation": "3/4 x 2/1 = 6/4 = 3/2"
          }
        ]
      }
      ''';

      // Seed version 2
      final seededV2 = await QuestionDao.seedQuestionBank(
        jsonContent: version2JsonContent,
        database: db,
      );
      expect(seededV2, isTrue);

      final totalCount = await QuestionDao.getTotalQuestionCount(database: db);
      expect(totalCount, equals(5)); // 4 original + 1 new, no duplicates

      // Verify that existing questions kept their original IDs
      final reloadedFractions = await QuestionDao.getQuestionsByTopic('Fractions', database: db);
      expect(reloadedFractions.length, equals(3));
      final reloadedQ1 = reloadedFractions.firstWhere((q) => q.questionText == 'What is 1/2 + 1/4?');
      final reloadedQ2 = reloadedFractions.firstWhere((q) => q.questionText == 'What is 2/3 x 3/4?');
      expect(reloadedQ1.id, equals(originalId1));
      expect(reloadedQ2.id, equals(originalId2));

      // New question has a newly generated ID
      final newQ = reloadedFractions.firstWhere((q) => q.questionText.contains('divided by'));
      expect(newQ.id, isNotNull);
      expect(newQ.id != originalId1 && newQ.id != originalId2, isTrue);
    });

    test('QuestionDao re-seeds with empty question bank and clears questions & progress safely', () async {
      // First seed with version 1 sample content
      await QuestionDao.seedQuestionBank(
        jsonContent: sampleJsonContent,
        database: db,
      );
      expect(await QuestionDao.getTotalQuestionCount(database: db), equals(4));

      // Record some progress on demo topic
      await ProgressDao.saveAnswer(
        topic: 'Fractions',
        difficulty: 1,
        isCorrect: true,
        database: db,
      );
      final initialAcc = await ProgressDao.getTopicAccuracy('Fractions', database: db);
      expect(initialAcc, equals(1.0));

      // Seed with empty questions and bumped version 2
      const emptyJson = '{"data_version": 2, "questions": []}';
      final seededEmpty = await QuestionDao.seedQuestionBank(
        jsonContent: emptyJson,
        database: db,
      );
      expect(seededEmpty, isTrue);

      // Verify questions table is completely empty
      final totalAfter = await QuestionDao.getTotalQuestionCount(database: db);
      expect(totalAfter, equals(0));

      final topicsAfter = await QuestionDao.getTopicsWithCounts(database: db);
      expect(topicsAfter, isEmpty);

      final randomAfter = await QuestionDao.getRandomQuestions(
        topic: 'Fractions',
        database: db,
      );
      expect(randomAfter, isEmpty);

      // Verify progress data was cleared safely
      final progressModelsAfter = await ProgressDao.getAllProgressModels(database: db);
      expect(progressModelsAfter, isEmpty);
      final overallAccAfter = await ProgressDao.getOverallAccuracy(database: db);
      expect(overallAccAfter, equals(0.0));
    });

    test('ProgressDao clearAllProgress and clearProgressForTopics operate cleanly', () async {
      await ProgressDao.saveAnswer(topic: 'DemoTopic1', difficulty: 1, isCorrect: true, database: db);
      await ProgressDao.saveAnswer(topic: 'DemoTopic2', difficulty: 2, isCorrect: false, database: db);

      final modelsBefore = await ProgressDao.getAllProgressModels(database: db);
      expect(modelsBefore.length, equals(2));

      await ProgressDao.clearProgressForTopics(['DemoTopic1'], database: db);
      final modelsMid = await ProgressDao.getAllProgressModels(database: db);
      expect(modelsMid.length, equals(1));
      expect(modelsMid.containsKey('DemoTopic2'), isTrue);

      await ProgressDao.clearAllProgress(database: db);
      final modelsAfter = await ProgressDao.getAllProgressModels(database: db);
      expect(modelsAfter, isEmpty);
    });
  });
}
