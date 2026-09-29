import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapps/constants/app_constants.dart';
import 'package:mobileapps/services/adaptive_engine.dart';

void main() {
  group('AdaptiveEngine Foundation Tests', () {
    late AdaptiveEngine engine;

    setUp(() {
      engine = AdaptiveEngine();
      engine.reset();
    });

    test('Initial difficulty should be easy (1)', () {
      expect(engine.currentDifficulty, AppConstants.difficultyEasy);
    });

    test('3 consecutive correct answers should upgrade difficulty to medium (2)', () {
      engine.processAnswer(isCorrect: true);
      engine.processAnswer(isCorrect: true);
      final diff = engine.processAnswer(isCorrect: true);

      expect(diff, AppConstants.difficultyMedium);
      expect(engine.currentDifficulty, AppConstants.difficultyMedium);
    });

    test('2 consecutive wrong answers should downgrade difficulty to easy (1)', () {
      // First promote to medium
      engine.processAnswer(isCorrect: true);
      engine.processAnswer(isCorrect: true);
      engine.processAnswer(isCorrect: true);
      expect(engine.currentDifficulty, AppConstants.difficultyMedium);

      // Now 2 wrong answers
      engine.processAnswer(isCorrect: false);
      final diff = engine.processAnswer(isCorrect: false);

      expect(diff, AppConstants.difficultyEasy);
      expect(engine.currentDifficulty, AppConstants.difficultyEasy);
    });
  });
}
