/// Model representing an offline sync entry/queue item for cloud synchronization.
class SyncLogModel {
  final int? id;
  final String action; // e.g., 'quiz_completed', 'progress_updated'
  final String payload; // JSON representation of the data
  final String status; // 'pending', 'synced', 'failed'
  final DateTime timestamp;

  const SyncLogModel({
    this.id,
    required this.action,
    required this.payload,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'action': action,
      'payload': payload,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncLogModel.fromMap(Map<String, dynamic> map) {
    return SyncLogModel(
      id: map['id'] as int?,
      action: map['action'] as String? ?? '',
      payload: map['payload'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
