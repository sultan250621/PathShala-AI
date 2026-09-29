import 'dart:async';

/// Architectural foundation for detecting network availability.
/// (Foundation for Week 6 roadmap: sync-when-available).
class ConnectivityService {
  static final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  /// Stream of connection states (true = online, false = offline).
  static Stream<bool> get onConnectivityChanged =>
      _connectivityController.stream;

  /// Check current network connectivity state (offline-first default: false).
  static Future<bool> isConnected() async {
    return false;
  }

  /// Broadcast a change in connectivity (used for testing or native events).
  static void updateStatus(bool isConnected) {
    _connectivityController.add(isConnected);
  }
}
