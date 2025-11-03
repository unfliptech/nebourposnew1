import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/connectivity_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../router/route_guards.dart';
import '../../../../shared/widgets/app_scaffold.dart';

class OfflineBlockedScreen extends ConsumerWidget {
  const OfflineBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectivityStatusProvider);
    final status = statusAsync.value;
    final isOnline = status == ConnectivityStatus.online;
    final guards = ref.watch(routeGuardsProvider);
    final pendingPath = guards.pendingPath;
    final recordedAt = guards.pendingRecordedAt;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    final subtitleColor =
        theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return AppScaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------- Illustration ----------
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 90,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ---------- Title ----------
                  Text(
                    'You’re Offline',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ---------- Subtitle ----------
                  Text(
                    'Please connect to the internet to continue using this app. '
                    'Some features require an active network connection.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: subtitleColor,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ---------- Status Banner ----------
                  _StatusBanner(isOnline: isOnline),
                  const SizedBox(height: 24),

                  // ---------- Pending Path (if any) ----------
                  if (pendingPath != null)
                    _PendingActionDetails(
                      path: pendingPath,
                      recordedAt: recordedAt,
                    ),

                  const SizedBox(height: 32),

                  // ---------- Retry Button ----------
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFED2433), // red theme
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      label: const Text(
                        'Retry Connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () async {
                        final success = await ref
                            .read(routeGuardsProvider)
                            .retryPending(context);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Still offline. Check your network connection and try again.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ---------- Footer ----------
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                      children: const [
                        TextSpan(text: 'Need help?  '),
                        TextSpan(
                          text: 'support@nebour.app',
                          style: TextStyle(
                            color: Color(0xFF00AEEF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(text: '  |  Version 0.01'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isOnline ? colors.primary : colors.error;
    final icon = isOnline ? Icons.wifi : Icons.wifi_off;
    final label = isOnline ? 'Online' : 'Offline';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            'Network status: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingActionDetails extends StatelessWidget {
  const _PendingActionDetails({
    required this.path,
    required this.recordedAt,
  });

  final String path;
  final DateTime? recordedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = recordedAt?.toLocal().toIso8601String();
    final actionLabel = switch (path) {
      '/sign-in' => 'Device login',
      '/passcode' => 'Passcode unlock',
      _ => path,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last pending action:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            actionLabel,
            style: theme.textTheme.bodyMedium,
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Recorded at: $timestamp',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
