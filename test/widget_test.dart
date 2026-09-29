import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapps/models/question_model.dart';
import 'package:mobileapps/screens/quiz_screen.dart';
import 'package:mobileapps/widgets/connectivity_banner.dart';
import 'package:mobileapps/widgets/progress_card.dart';

void main() {
  group('Widget and UI Feedback Tests', () {
    testWidgets('ConnectivityBanner displays Offline Mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(isOnline: false),
          ),
        ),
      );

      expect(find.text('Offline Mode'), findsOneWidget);
    });

    testWidgets('ProgressCard renders topic and percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressCard(
              topic: 'Algebra',
              percent: 0.8,
              questionCount: 10,
            ),
          ),
        ),
      );

      expect(find.text('Algebra'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('10 practice questions'), findsOneWidget);
      expect(find.text('Excellent understanding! 🌟'), findsOneWidget);
    });

    testWidgets('Selecting an answer in the quiz shows feedback', (WidgetTester tester) async {
      const sampleQuestion = QuestionModel(
        topic: 'Basic Algebra',
        difficulty: 1,
        questionText: 'What is x if x + 2 = 5?',
        optionA: '3',
        optionB: '7',
        optionC: '2',
        optionD: '10',
        correctOption: 'A',
        hint: 'Subtract 2 from 5',
        explanation: 'x = 5 - 2 = 3',
      );

      // Render QuizScreen with initialQuestions
      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(
            topic: 'Basic Algebra',
            initialQuestions: [sampleQuestion],
          ),
        ),
      );

      await tester.pump();

      // Verify question and options rendered
      expect(find.text('What is x if x + 2 = 5?'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      // Feedback should NOT be visible initially
      expect(find.text('Well done! That is correct. ✨'), findsNothing);
      expect(find.text('Next Question'), findsNothing);
      expect(find.text('View Results'), findsNothing);

      // Tap on correct option '3' (Option A)
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Feedback message and action button should now be visible
      expect(
        find.text('Well done! That is correct. ✨', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('View Results'), findsOneWidget);
    });

    test('QuestionModel serialization and helper test', () {
      const q = QuestionModel(
        topic: 'Fractions',
        difficulty: 1,
        questionText: '1/2 + 1/4 = ?',
        optionA: '3/4',
        optionB: '2/6',
        optionC: '1/6',
        optionD: '2/4',
        correctOption: 'A',
        hint: 'Find the common denominator.',
        explanation: '1/2 = 2/4. 2/4 + 1/4 = 3/4.',
      );

      final map = q.toMap();
      final fromMapQ = QuestionModel.fromMap(map);

      expect(fromMapQ.topic, 'Fractions');
      expect(fromMapQ.correctOption, 'A');
      expect(fromMapQ.correctOptionText, '3/4');
      expect(fromMapQ.hint, 'Find the common denominator.');
      expect(fromMapQ.explanation, '1/2 = 2/4. 2/4 + 1/4 = 3/4.');
    });
  });
}
