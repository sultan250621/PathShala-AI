import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Quiz answer sync service.
/// Firestore Android e offline e write queue kore rakhe, internet ashle
/// nijei server e upload kore.
class FirebaseSyncService {
  FirebaseSyncService._();
  static final FirebaseSyncService instance = FirebaseSyncService._();

  // Anonymous session ID: naam ba personal info jay na.
  static final String _sessionId = DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> recordAnswer({
    required String topic,
    required int difficulty,
    required bool isCorrect,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('answers').add({
        'sessionId': _sessionId,
        'topic': topic,
        'difficulty': difficulty,
        'isCorrect': isCorrect,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Offline e Firestore nijei queue kore rakhe
    }
  }

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}