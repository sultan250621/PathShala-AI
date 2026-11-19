import 'package:flutter/material.dart';

import '../services/doubt_solver_service.dart';

/// Button shown on the quiz screen AFTER the student has answered.
class DoubtSolverButton extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final String correctOption; // 'A'..'D'
  final String? bookExplanation;

  const DoubtSolverButton({
    super.key,
    required this.questionText,
    required this.options,
    required this.correctOption,
    this.bookExplanation,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => DoubtSolverSheet(
          questionText: questionText,
          options: options,
          correctOption: correctOption,
          bookExplanation: bookExplanation,
        ),
      ),
      icon: const Icon(Icons.psychology_alt_outlined),
      label: const Text('Doubt Solver'),
    );
  }
}

class DoubtSolverSheet extends StatefulWidget {
  final String questionText;
  final List<String> options;
  final String correctOption;
  final String? bookExplanation;

  const DoubtSolverSheet({
    super.key,
    required this.questionText,
    required this.options,
    required this.correctOption,
    this.bookExplanation,
  });

  @override
  State<DoubtSolverSheet> createState() => _DoubtSolverSheetState();
}

class _DoubtSolverSheetState extends State<DoubtSolverSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  DoubtResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _result = null;
    });
    final res = await DoubtSolverService.instance.ask(
      questionText: widget.questionText,
      options: widget.options,
      correctOption: widget.correctOption,
      bookExplanation: widget.bookExplanation,
      studentDoubt: _controller.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = res;
    });
  }

  String _label(DoubtResult r) {
    switch (r.source) {
      case DoubtSource.model:
        final s = ((r.elapsed?.inMilliseconds ?? 0) / 1000).toStringAsFixed(1);
        return 'AI (offline) • $s সেকেন্ড';
      case DoubtSource.bookExplanation:
        return 'বইয়ের ব্যাখ্যা';
      case DoubtSource.unavailable:
        return 'Doubt Solver';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doubt Solver', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(widget.questionText, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'তোমার প্রশ্ন লেখো (না লিখলে উত্তরটি বুঝিয়ে দেবে)',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _ask,
                child: const Text('জিজ্ঞাসা করো'),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              Column(
                children: [
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: DoubtSolverService.instance.statusText,
                    builder: (_, status, _) => Text(
                      status.isEmpty
                          ? 'উত্তর তৈরি হচ্ছে... প্রথমবার একটু সময় লাগতে পারে'
                          : status,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(_result!), style: theme.textTheme.labelMedium),
                    const SizedBox(height: 6),
                    Text(_result!.text, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
