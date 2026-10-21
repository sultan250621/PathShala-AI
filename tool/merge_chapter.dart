// ignore_for_file: avoid_print
import 'dart:io';
import 'package:mobileapps/services/question_bank_merger.dart';

/// CLI Tool to merge chapter question files into assets/data/nctb_math_questions.json.
///
/// Usage:
///   `dart run tool/merge_chapter.dart <path_to_chapter_file> [optional_target_path]`
///
/// Example:
///   `dart run tool/merge_chapter.dart assets/data/chapters/chapter_1_integers.json`
void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    stdout.writeln('''
PathShala AI - Chapter Question Merger CLI
------------------------------------------
Usage:
  dart run tool/merge_chapter.dart <chapter_json_path> [target_json_path]

Example:
  dart run tool/merge_chapter.dart assets/data/chapters/chapter_1_integers.json
  dart run tool/merge_chapter.dart assets/data/chapters/chapter_2_fractions.json

Description:
  Merges questions from the given chapter file into the main question bank
  (assets/data/nctb_math_questions.json by default), appends new questions,
  avoids duplicates, and bumps data_version by 1.
''');
    exit(args.isEmpty ? 1 : 0);
  }

  final chapterPath = args[0];
  final targetPath = args.length > 1 ? args[1] : QuestionBankMerger.defaultTargetPath;

  try {
    stdout.writeln('Reading and merging "$chapterPath" into "$targetPath"...');
    final result = await QuestionBankMerger.mergeChapterFile(
      chapterPath: chapterPath,
      targetPath: targetPath,
    );
    stdout.writeln(result.toString());
    stdout.writeln('Merge completed successfully.');
  } catch (e, stack) {
    stderr.writeln('Error during chapter merge: $e');
    stderr.writeln(stack);
    exit(1);
  }
}
