import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../database/progress_dao.dart';
import '../database/question_dao.dart';
import '../models/progress_model.dart';
import '../services/question_loader_service.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/progress_card.dart';
import '../widgets/state_views.dart';
import 'quiz_screen.dart';
import 'topic_selection_screen.dart';

/// Main Dashboard screen showing subject navigation, offline chip, and real topic progress.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, int> _topicCounts = {};
  Map<String, ProgressModel> _progressMap = {};
  double _overallAccuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initial setup: seeds question bank if needed and loads topic progress.
  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Seed database from asset if version updated
      await QuestionLoaderService.seedQuestionBank();

      // 2. Fetch topic counts and real progress
      await _loadData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load question bank or progress data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final topicCounts = await QuestionDao.getTopicsWithCounts(
        classLevel: AppConstants.defaultClassLevel,
      );
      final progressMap = await ProgressDao.getAllProgressModels();
      final overallAcc = await ProgressDao.getOverallAccuracy();

      if (mounted) {
        setState(() {
          _topicCounts = topicCounts;
          _progressMap = progressMap;
          _overallAccuracy = overallAcc;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading progress: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingStateView(message: 'Loading mathematics curriculum...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        errorMessage: _errorMessage!,
        onRetry: _initializeApp,
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // ---- Header Bar ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PathShala AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Offline Mathematics Tutor',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const ConnectivityBanner(isOnline: false),
          ],
        ),
        const SizedBox(height: 18),

        // ---- Greeting & Welcome Card ----
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'NCTB Curriculum • Class 6',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Mathematics - Class 6',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Practice Class 6 mathematics topics offline anytime.',
                style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.3),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopicSelectionScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                label: const Text(
                  'Start Practicing',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(0, AppConstants.minTapTargetSize),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---- Summary Banner ----
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                label: 'Topics Available',
                value: '${_topicCounts.length}',
                icon: Icons.topic_rounded,
                color: AppColors.primary,
              ),
              Container(width: 1, height: 40, color: AppColors.cardBorder),
              _buildMetricItem(
                label: 'Overall Accuracy',
                value: '${(_overallAccuracy * 100).round()}%',
                icon: Icons.insights_rounded,
                color: AppColors.success,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---- Topic-wise Progress Overview ----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Topic Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TopicSelectionScreen(),
                  ),
                ).then((_) => _loadData());
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_topicCounts.isEmpty)
          EmptyStateView(
            icon: Icons.menu_book_rounded,
            title: 'No Topics Found',
            message: 'Question bank has not been initialized.',
            actionLabel: 'Re-seed Question Bank',
            onAction: () async {
              await QuestionLoaderService.seedQuestionBank(force: true);
              await _loadData();
            },
          )
        else
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
                    builder: (context) => QuizScreen(topic: topic),
                  ),
                ).then((_) => _loadData());
              },
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
