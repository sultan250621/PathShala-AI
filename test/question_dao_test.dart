import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobileapps/constants/app_constants.dart';
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
  });
}
