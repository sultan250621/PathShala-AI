import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../database/progress_dao.dart';
import '../database/question_dao.dart';
import '../models/question_model.dart';
import '../widgets/hint_bottom_sheet.dart';
import '../widgets/state_views.dart';
import 'quiz_result_screen.dart';

/// Practice Quiz screen with gentle student feedback, hint sheet, and progress tracking.
class QuizScreen extends StatefulWidget {
  final String topic;
  final int classLevel;
  final List<QuestionModel>? initialQuestions;
  final Database? database;

  const QuizScreen({
    super.key,
    required this.topic,
    this.classLevel = AppConstants.defaultClassLevel,
    this.initialQuestions,
    this.database,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  int _currentIndex = 0;

  String? _selectedOptionKey; // 'A', 'B', 'C', or 'D'
  bool _hasAnswered = false;

  int _correctCount = 0;
  int _wrongCount = 0;

  // Session timer
  late final Stopwatch _stopwatch;

  // Session records for result review
  final List<QuizAnswerRecord> _answerRecords = [];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _loadQuestions();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    if (widget.initialQuestions != null) {
      setState(() {
        _questions = widget.initialQuestions!;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Random selection without repeats
      final data = await QuestionDao.getRandomQuestions(
        topic: widget.topic,
        count: 10,
        classLevel: widget.classLevel,
        database: widget.database,
      );

      if (mounted) {
        setState(() {
          _questions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load quiz questions: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleOptionSelected(String optionKey) async {
    if (_hasAnswered) return;

    final currentQuestion = _questions[_currentIndex];
    final isCorrect = (optionKey.toUpperCase() == currentQuestion.correctOption.toUpperCase());

    setState(() {
      _selectedOptionKey = optionKey;
      _hasAnswered = true;
      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });

    // Record answer in session records for summary & review
    _answerRecords.add(
      QuizAnswerRecord(
        question: currentQuestion,
        selectedOption: optionKey,
        isCorrect: isCorrect,
      ),
    );

    // Save each answer immediately to SQLite
    try {
      await ProgressDao.saveAnswer(
        topic: widget.topic,
        difficulty: currentQuestion.difficulty,
        isCorrect: isCorrect,
        timestamp: DateTime.now(),
        database: widget.database,
      );
    } catch (e) {
      // Ignored in offline fallback
    }
  }

  void _goToNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionKey = null;
        _hasAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          topic: widget.topic,
          classLevel: widget.classLevel,
          correctCount: _correctCount,
          wrongCount: _wrongCount,
          timeTaken: elapsed,
          answerRecords: _answerRecords,
        ),
      ),
    );
  }

  Future<bool> _confirmLeaveQuiz() async {
    if (!_hasAnswered && _currentIndex == 0) {
      return true; // Nothing attempted yet, exit cleanly
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.accent),
            SizedBox(width: 10),
            Text('Leave Quiz?'),
          ],
        ),
        content: const Text(
          'Your current quiz session is in progress. Are you sure you want to return to topics?',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay & Practice'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmLeaveQuiz();
        if (canLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.topic,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
            onPressed: () async {
              final canLeave = await _confirmLeaveQuiz();
              if (canLeave && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingStateView(message: 'Preparing your quiz...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        errorMessage: _errorMessage!,
        onRetry: _loadQuestions,
      );
    }

    if (_questions.isEmpty) {
      return EmptyStateView(
        icon: Icons.menu_book_outlined,
        title: 'No Questions Found',
        message: 'No practice questions are available for this topic.',
        actionLabel: 'Return to Topics',
        onAction: () => Navigator.pop(context),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final totalQuestions = _questions.length;
    final progressFraction = (_currentIndex + 1) / totalQuestions;

    return Column(
      children: [
        // ---- Top Progress Header ----
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentIndex + 1} of $totalQuestions',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _buildDifficultyBadge(currentQuestion.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),

        // ---- Scrollable Question & Options ----
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion.questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hint trigger
                    if (currentQuestion.hint != null && currentQuestion.hint!.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => HintBottomSheet.show(context, currentQuestion.hint!),
                          icon: const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.accent),
                          label: const Text(
                            'Need a hint?',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4 Option Buttons
              ...['A', 'B', 'C', 'D'].map((key) {
                final optionText = currentQuestion.options[key] ?? '';
                return _buildOptionButton(key, optionText, currentQuestion);
              }),

              // Feedback Banner (Shown after answering)
              if (_hasAnswered) ...[
                const SizedBox(height: 16),
                _buildFeedbackCard(currentQuestion),
              ],
            ],
          ),
        ),

        // ---- Bottom Action Bar ----
        if (_hasAnswered)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: ElevatedButton(
              onPressed: _goToNextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(AppConstants.minTapTargetSize),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _currentIndex < _questions.length - 1 ? 'Next Question' : 'View Results',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDifficultyBadge(int difficulty) {
    String label = 'Easy';
    Color color = AppColors.success;
    if (difficulty == 2) {
      label = 'Medium';
      color = AppColors.accent;
    } else if (difficulty == 3) {
      label = 'Hard';
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOptionButton(String key, String text, QuestionModel question) {
    final isSelected = (_selectedOptionKey == key);
    final isCorrectOption = (key.toUpperCase() == question.correctOption.toUpperCase());

    Color cardBg = AppColors.surface;
    Color borderColor = AppColors.cardBorder;
    Color textColor = AppColors.textPrimary;
    Color badgeBg = const Color(0xFFF1F5F9);
    Color badgeFg = AppColors.textSecondary;

    if (_hasAnswered) {
      if (isCorrectOption) {
        // Soft green highlight on correct option
        cardBg = AppColors.successLight;
        borderColor = AppColors.success;
        textColor = AppColors.textPrimary;
        badgeBg = AppColors.success;
        badgeFg = Colors.white;
      } else if (isSelected) {
        // Soft red highlight on chosen wrong option
        cardBg = AppColors.errorLight;
        borderColor = AppColors.error;
        textColor = AppColors.textPrimary;
        badgeBg = AppColors.error;
        badgeFg = Colors.white;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: borderColor, width: isSelected || (_hasAnswered && isCorrectOption) ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          onTap: _hasAnswered ? null : () => _handleOptionSelected(key),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Option letter indicator (A, B, C, D)
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: badgeFg,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Option Text
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                ),
                // Feedback icon if answered
                if (_hasAnswered && isCorrectOption)
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)
                else if (_hasAnswered && isSelected)
                  const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(QuestionModel question) {
    final isCorrect = (_selectedOptionKey?.toUpperCase() == question.correctOption.toUpperCase());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successLight.withValues(alpha: 0.6) : AppColors.errorLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isCorrect ? AppColors.success.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.celebration_rounded : Icons.lightbulb_circle_rounded,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCorrect ? 'Well done! That is correct. ✨' : "Almost! Let's see why:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                question.explanation!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Record of an answered question during a quiz session.
class QuizAnswerRecord {
  final QuestionModel question;
  final String selectedOption;
  final bool isCorrect;

  const QuizAnswerRecord({
    required this.question,
    required this.selectedOption,
    required this.isCorrect,
  });
}
