import 'package:flutter/material.dart';

/// Modal bottom sheet / dialog displaying offline AI tutor hints.
class AIHintDialog extends StatelessWidget {
  final String title;
  final String content;
  final bool isLoading;

  const AIHintDialog({
    super.key,
    this.title = 'AI Tutor Hint',
    required this.content,
    this.isLoading = false,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'AI Tutor Hint',
    required String content,
    bool isLoading = false,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AIHintDialog(
        title: title,
        content: content,
        isLoading: isLoading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purple),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
