import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../database/progress_dao.dart';
import '../database/question_dao.dart';
import '../models/progress_model.dart';
import '../services/question_loader_service.dart';
import '../widgets/progress_card.dart';
import '../widgets/state_views.dart';
import 'quiz_screen.dart';

/// Screen displaying all available NCTB curriculum topics read dynamically from the database.
class TopicSelectionScreen extends StatefulWidget {
  final String subject;
  final int classLevel;

  const TopicSelectionScreen({
    super.key,
    this.subject = AppConstants.defaultSubject,
    this.classLevel = AppConstants.defaultClassLevel,
  });

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, int> _topicCounts = {};
  Map<String, ProgressModel> _progressMap = {};

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final counts = await QuestionDao.getTopicsWithCounts(classLevel: widget.classLevel);
      final progressMap = await ProgressDao.getAllProgressModels();

      if (mounted) {
        setState(() {
          _topicCounts = counts;
          _progressMap = progressMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load topics: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.subject} • Class ${widget.classLevel}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadTopics,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingStateView(message: 'Loading curriculum topics...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        errorMessage: _errorMessage!,
        onRetry: _loadTopics,
      );
    }

    if (_topicCounts.isEmpty) {
      return EmptyStateView(
        icon: Icons.topic_outlined,
        title: 'No Topics Available',
        message: 'No practice questions were found for Class ${widget.classLevel} ${widget.subject}.',
        actionLabel: 'Re-seed Question Bank',
        onAction: () async {
          await QuestionLoaderService.seedQuestionBank(force: true);
          await _loadTopics();
        },
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Header Info Card
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Select a topic below to begin practice. Questions adapt to your pace.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Topic Cards
        ..._topicCounts.entries.map((entry) {
          final topic = entry.key;
          final count = entry.value;
          final progress = _progressMap[topic];
          final percent = progress?.masteryPercentage ?? 0.0;

          return ProgressCard(
            topic: topic,
            percent: percent,
            questionCount: count,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    topic: topic,
                    classLevel: widget.classLevel,
                  ),
                ),
              ).then((_) => _loadTopics());
            },
          );
        }),
      ],
    );
  }
}
