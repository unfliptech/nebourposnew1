import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/data/connectivity_service.dart';
import '../../core/providers/core_providers.dart';
import '../../features/sync/presentation/providers/auto_sync_provider.dart';
import '../utils/app_toast.dart';

class CustomTitleBar extends ConsumerStatefulWidget {
  const CustomTitleBar({super.key});

  @override
  ConsumerState<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends ConsumerState<CustomTitleBar> {
  bool _checkingConnection = false;
  ConnectivityStatus? _lastToastStatus;
  ConnectivityStatus? _overrideStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final connectivity = ref.watch(connectivityStatusProvider);
    final autoSyncState = ref.watch(autoSyncControllerProvider);
    final isSyncing = autoSyncState.status == AutoSyncStatus.syncing;
    final lastSyncAt = autoSyncState.lastCompletedAt?.toLocal();

    final bg = isDark ? const Color(0xFF0C0C0C) : Colors.grey[200];
    final fg = isDark ? Colors.white : const Color(0xFF000000);

    return Container(
      height: 28,
      color: bg,
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: () async {
                final isMax = await windowManager.isMaximized();
                if (isMax) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 16,
                      height: 16,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                  Text(
                    'Nebour POS',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildConnectivityIndicator(connectivity, isSyncing),
                  const SizedBox(width: 16),
                  _buildLastSyncLabel(fg, lastSyncAt, isSyncing),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _WindowButton(
                icon: Icons.remove,
                iconSize: 13,
                onPressed: () => windowManager.minimize(),
              ),
              _WindowButton(
                icon: Icons.crop_square,
                iconSize: 12,
                onPressed: () async {
                  final isMax = await windowManager.isMaximized();
                  if (isMax) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _WindowButton(
                icon: Icons.close,
                iconSize: 13,
                hoverColor: Colors.redAccent,
                onPressed: () => windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityIndicator(
    AsyncValue<ConnectivityStatus> connectivity,
    bool isSyncing,
  ) {
    return connectivity.when(
      loading: () => const _StatusCapsule(
        icon: Icons.sync,
        iconColor: Colors.blueGrey,
        label: 'Checking connection...',
      ),
      error: (_, __) => const _StatusCapsule(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        label: 'Status unavailable',
      ),
      data: (status) {
        final effectiveStatus = _overrideStatus ?? status;

        if (!_checkingConnection) {
          if (_lastToastStatus == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _lastToastStatus = effectiveStatus);
              }
            });
          } else if (_lastToastStatus != effectiveStatus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final message = effectiveStatus == ConnectivityStatus.online
                  ? 'Internet connection restored.'
                  : 'Internet connection lost.';
              final type = effectiveStatus == ConnectivityStatus.online
                  ? AppToastType.success
                  : AppToastType.error;
              showAppToast(context, message, type);
              setState(() => _lastToastStatus = effectiveStatus);
            });
          }
        }

        if (_overrideStatus != null && _overrideStatus == status) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _overrideStatus = null);
            }
          });
        }

        if (_checkingConnection) {
          return const _StatusCapsule(
            icon: Icons.sync,
            iconColor: Colors.blueGrey,
            label: 'Connecting...',
          );
        }

        if (effectiveStatus == ConnectivityStatus.online) {
          return _StatusCapsule(
            icon: Icons.circle,
            iconColor: Colors.green,
            label: isSyncing ? 'Connected - Syncing...' : 'Connected',
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StatusCapsule(
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              label: 'Computer not connected',
            ),
            const SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed:
                  (_checkingConnection) ? null : () => _checkConnectivity(),
              child: const Text('Reconnect'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLastSyncLabel(Color fg, DateTime? lastSyncAt, bool isSyncing) {
    final formatter = DateFormat('dd MMM yyyy - hh:mm a');
    final formatted = lastSyncAt == null ? '--' : formatter.format(lastSyncAt);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_outlined,
          size: 14,
          color: fg.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          isSyncing ? 'Last sync: running...' : 'Last sync: $formatted',
          style: TextStyle(
            color: fg.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Future<void> _checkConnectivity() async {
    if (_checkingConnection) return;
    setState(() => _checkingConnection = true);
    final service = ref.read(connectivityServiceProvider);
    final status = await service.checkStatus();
    if (!mounted) return;

    final message = status == ConnectivityStatus.online
        ? 'Internet connection restored.'
        : 'Internet connection lost.';
    final type = status == ConnectivityStatus.online
        ? AppToastType.success
        : AppToastType.error;

    showAppToast(context, message, type);

    setState(() {
      _checkingConnection = false;
      _overrideStatus = status;
      _lastToastStatus = status;
    });
  }
}

class _StatusCapsule extends StatelessWidget {
  const _StatusCapsule({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color? hoverColor;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.iconSize = 14,
    this.hoverColor,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fg = Colors.white.withValues(alpha: _hovering ? 1.0 : 0.85);
    final hoverBg = widget.hoverColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.1));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 28,
          color: _hovering ? hoverBg : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: fg,
          ),
        ),
      ),
    );
  }
}
