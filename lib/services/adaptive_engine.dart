import '../constants/app_constants.dart';

/// Service responsible for rule-based adaptive difficulty calculation.
/// (Architectural foundation for Week 5 roadmap).
class AdaptiveEngine {
  int _consecutiveCorrect = 0;
  int _consecutiveWrong = 0;
  int _currentDifficulty = AppConstants.difficultyEasy;

  int get currentDifficulty => _currentDifficulty;
  int get consecutiveCorrect => _consecutiveCorrect;
  int get consecutiveWrong => _consecutiveWrong;

  /// Reset the engine state for a new quiz session.
  void reset([int initialDifficulty = AppConstants.difficultyEasy]) {
    _consecutiveCorrect = 0;
    _consecutiveWrong = 0;
    _currentDifficulty = initialDifficulty;
  }

  /// Process an answer result and determine if difficulty level should adapt.
  /// Rule:
  /// - 3 consecutive correct -> upgrade difficulty
  /// - 2 consecutive wrong -> downgrade difficulty
  int processAnswer({required bool isCorrect}) {
    if (isCorrect) {
      _consecutiveCorrect++;
      _consecutiveWrong = 0;
      if (_consecutiveCorrect >= 3) {
        _upgradeDifficulty();
        _consecutiveCorrect = 0;
      }
    } else {
      _consecutiveWrong++;
      _consecutiveCorrect = 0;
      if (_consecutiveWrong >= 2) {
        _downgradeDifficulty();
        _consecutiveWrong = 0;
      }
    }
    return _currentDifficulty;
  }

  void _upgradeDifficulty() {
    if (_currentDifficulty == AppConstants.difficultyEasy) {
      _currentDifficulty = AppConstants.difficultyMedium;
    } else if (_currentDifficulty == AppConstants.difficultyMedium) {
      _currentDifficulty = AppConstants.difficultyHard;
    }
  }

  void _downgradeDifficulty() {
    if (_currentDifficulty == AppConstants.difficultyHard) {
      _currentDifficulty = AppConstants.difficultyMedium;
    } else if (_currentDifficulty == AppConstants.difficultyMedium) {
      _currentDifficulty = AppConstants.difficultyEasy;
    }
  }
}
