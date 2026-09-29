import 'package:flutter/material.dart';

/// Indicator chip / banner displaying the app's offline/online synchronization state.
class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;

  const ConnectivityBanner({
    super.key,
    this.isOnline = false,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String text;

    if (isSyncing) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
      icon = Icons.sync;
      text = 'Syncing progress...';
    } else if (isOnline) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      icon = Icons.cloud_done;
      text = 'Online & Synced';
    } else {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      icon = Icons.cloud_off;
      text = 'Offline Mode';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
