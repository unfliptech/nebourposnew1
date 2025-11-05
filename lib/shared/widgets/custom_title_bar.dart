import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/providers/shell_providers.dart';

class CustomTitleBar extends ConsumerStatefulWidget {
  const CustomTitleBar({super.key});

  @override
  ConsumerState<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends ConsumerState<CustomTitleBar>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _sync();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _sync() async {
    final m = await windowManager.isMaximized();
    if (mounted) setState(() => _isMaximized = m);
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);
  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = ref.watch(pageTitleProvider);
    final isDark = theme.brightness == Brightness.dark;
    final logoAsset = isDark ? 'assets/icon/icon.png' : 'assets/icon/icon.png';

    const height = 36.0;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // FULL drag region (left side) — opaque so it captures clicks
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: () async {
                final maximized = await windowManager.isMaximized();
                if (maximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              onPanStart: (_) => windowManager.startDragging(),
              child: Row(
                children: [
                  Image.asset(logoAsset, height: 18, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Window buttons (not draggable)
          Row(
            children: [
              _CaptionButton(
                tooltip: 'Minimize',
                icon: Icons.remove_rounded,
                onTap: () => windowManager.minimize(),
              ),
              const SizedBox(width: 4),
              _CaptionButton(
                tooltip: _isMaximized ? 'Restore' : 'Maximize',
                icon: _isMaximized
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                onTap: () async {
                  final maximized = await windowManager.isMaximized();
                  if (maximized) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              const SizedBox(width: 4),
              _CaptionButton(
                tooltip: 'Close',
                icon: Icons.close_rounded,
                isClose: true,
                onTap: () => windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatelessWidget {
  const _CaptionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isClose = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool isClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 26,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isClose
                ? theme.colorScheme.error.withOpacity(0.06)
                : theme.colorScheme.surfaceVariant.withOpacity(0.4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isClose
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
