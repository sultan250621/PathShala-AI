import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import 'quiz_screen.dart';

/// Screen displaying quiz completion summary, score breakdown, and answer review.
class QuizResultScreen extends StatelessWidget {
  final String topic;
  final int classLevel;
  final int correctCount;
  final int wrongCount;
  final Duration timeTaken;
  final List<QuizAnswerRecord> answerRecords;

  QuizResultScreen({
    super.key,
    required this.topic,
    this.classLevel = AppConstants.defaultClassLevel,
    required this.correctCount,
    required this.wrongCount,
    required this.timeTaken,
    this.answerRecords = const [],
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes min $seconds sec';
    }
    return '$seconds sec';
  }

  void _showReviewSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle & title
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Answer Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Questions list
                  Expanded(
                    child: answerRecords.isEmpty
                        ? Center(
                            child: Text(
                              'No question details available.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: answerRecords.length,
                            separatorBuilder: (context, index) => SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final record = answerRecords[index];
                              final q = record.question;
                              final isCorrect = record.isCorrect;

                              return Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                                  border: Border.all(
                                    color: isCorrect
                                        ? AppColors.success.withValues(alpha: 0.3)
                                        : AppColors.error.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isCorrect ? AppColors.successLight : AppColors.errorLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Q${index + 1} • ${isCorrect ? "Correct" : "Incorrect"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isCorrect ? AppColors.success : AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      q.questionText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Your answer: Option ${record.selectedOption} (${q.options[record.selectedOption] ?? ""})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isCorrect ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                    if (!isCorrect) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        'Correct answer: Option ${q.correctOption} (${q.correctOptionText})',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = correctCount + wrongCount;
    final double percentage = total > 0 ? (correctCount / total) : 0.0;
    final int percentInt = (percentage * 100).round();

    String encouragingMessage;
    String subMessage;
    IconData statusIcon;
    Color themeColor;

    if (percentage >= 0.8) {
      encouragingMessage = 'Outstanding Work! 🌟';
      subMessage = 'You have mastered this concept remarkably well.';
      statusIcon = Icons.military_tech_rounded;
      themeColor = AppColors.success;
    } else if (percentage >= 0.5) {
      encouragingMessage = 'Great Effort! 👏';
      subMessage = 'You are making steady progress. A little more practice will make it perfect.';
      statusIcon = Icons.thumb_up_alt_rounded;
      themeColor = AppColors.accent;
    } else {
      encouragingMessage = 'Keep Going! 💪';
      subMessage = 'Every mistake is a learning opportunity. Review your answers and try once more!';
      statusIcon = Icons.auto_awesome_rounded;
      themeColor = AppColors.primary;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Quiz Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Score Circle
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: percentage,
                          strokeWidth: 10,
                          backgroundColor: Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: themeColor, size: 28),
                          Text(
                            '$percentInt%',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Encouraging text
                  Text(
                    encouragingMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    subMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Topic: $topic',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Performance Breakdown Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        label: 'Correct',
                        value: '$correctCount',
                        color: AppColors.success,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      Container(width: 1, height: 40, color: AppColors.cardBorder),
                      _buildMetric(
                        label: 'Incorrect',
                        value: '$wrongCount',
                        color: AppColors.error,
                        icon: Icons.cancel_outlined,
                      ),
                      Container(width: 1, height: 40, color: AppColors.cardBorder),
                      _buildMetric(
                        label: 'Time Taken',
                        value: _formatDuration(timeTaken),
                        color: AppColors.accent,
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () => _showReviewSheet(context),
              icon: Icon(Icons.rate_review_outlined),
              label: Text('Review Answers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: Size.fromHeight(AppConstants.minTapTargetSize),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      topic: topic,
                      classLevel: classLevel,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.refresh_rounded),
              label: Text('Practice Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(AppConstants.minTapTargetSize),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: Size.fromHeight(AppConstants.minTapTargetSize),
              ),
              child: Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
