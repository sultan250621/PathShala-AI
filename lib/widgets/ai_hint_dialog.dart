import 'package:flutter/material.dart';

/// Modal bottom sheet / dialog displaying offline AI tutor hints.
class AIHintDialog extends StatelessWidget {
  final String title;
  final String content;
  final bool isLoading;

  AIHintDialog({
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
      shape: RoundedRectangleBorder(
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
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Text(
              content,
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
