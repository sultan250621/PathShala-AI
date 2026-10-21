import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../database/question_dao.dart';

/// Service responsible for loading question bank JSON and seeding SQLite database.
class QuestionLoaderService {
  /// Loads question bank from asset bundle and seeds database if data_version increased.
  /// Set [force] to true to force seeding regardless of version.
  /// Delegates to [QuestionDao.seedQuestionBank].
  static Future<bool> seedQuestionBank({
    String assetPath = AppConstants.questionBankAsset,
    String? jsonContent,
    Database? database,
    bool force = false,
  }) async {
    return QuestionDao.seedQuestionBank(
      assetPath: assetPath,
      jsonContent: jsonContent,
      database: database,
      force: force,
    );
  }
}
