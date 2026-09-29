import '../database/progress_dao.dart';
import 'connectivity_service.dart';

/// Architectural foundation for cloud synchronization.
/// (Foundation for Week 6 roadmap: sync-when-available).
class SyncService {
  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;

  /// Attempt synchronization if connectivity is available.
  static Future<bool> syncPendingData() async {
    final online = await ConnectivityService.isConnected();
    if (!online) {
      return false; // Safely skip when offline
    }

    _isSyncing = true;
    try {
      final unsynced = await ProgressDao.getUnsyncedProgress();
      if (unsynced.isEmpty) {
        _isSyncing = false;
        return true;
      }

      // Placeholder for Firebase/Firestore sync batch in Step 6
      final syncedTopics = unsynced.map((p) => p.topic).toList();
      await ProgressDao.markAsSynced(syncedTopics);

      _isSyncing = false;
      return true;
    } catch (_) {
      _isSyncing = false;
      return false;
    }
  }
}
