import 'package:flutter/material.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.status,
  });

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (color, label) = switch (status) {
      SyncStatus.idle => (colors.primary, 'Idle'),
      SyncStatus.syncing => (colors.tertiary, 'Syncing'),
      SyncStatus.success => (colors.primary, 'Up to date'),
      SyncStatus.error => (colors.error, 'Error'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha((0.4 * 255).round())),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.2,
        ),
        child: Text(label),
      ),
    );
  }
}
