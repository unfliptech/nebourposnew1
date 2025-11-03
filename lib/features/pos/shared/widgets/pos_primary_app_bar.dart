import 'package:flutter/material.dart';

/// Primary POS app bar that mirrors the desktop mock with logo,
/// new-order CTA, support blurb, and quick utility icons.
class PosPrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PosPrimaryAppBar({
    super.key,
    this.onMenuTap,
    this.onNewOrderTap,
    this.onManualSyncTap,
    this.onLockTap,
    this.onLogoutTap,
    this.isManualSyncing = false,
  });

  final VoidCallback? onMenuTap;
  final VoidCallback? onNewOrderTap;
  final VoidCallback? onManualSyncTap;
  final VoidCallback? onLockTap;
  final VoidCallback? onLogoutTap;
  final bool isManualSyncing;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.colorScheme.surface : Colors.white;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    return Material(
      color: bgColor,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: borderColor, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              _IconActionButton(
                icon: Icons.menu_rounded,
                tooltip: 'Menu',
                onPressed: onMenuTap,
              ),
              const SizedBox(width: 16),
              Image.asset(
                isDark
                    ? 'assets/nebour-logo-light.png'
                    : 'assets/nebour-logo-dark.png',
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onNewOrderTap,
                child: const Text(
                  'NEW ORDER',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              const _SupportContact(),
              const SizedBox(width: 24),
              Wrap(
                spacing: 12,
                children: [
                  _IconActionButton(
                    icon: Icons.sync_outlined,
                    tooltip: isManualSyncing ? 'Syncing...' : 'Manual Sync',
                    onPressed: isManualSyncing ? null : onManualSyncTap,
                    isBusy: isManualSyncing,
                  ),
                  const _IconActionButton(
                    icon: Icons.history,
                    tooltip: 'Activity',
                  ),
                  const _IconActionButton(
                    icon: Icons.person_outline,
                    tooltip: 'Profile',
                  ),
                  const _IconActionButton(
                    icon: Icons.list_alt_outlined,
                    tooltip: 'Tickets',
                  ),
                  _IconActionButton(
                    icon: Icons.lock_outline,
                    tooltip: 'Lock (Passcode)',
                    onPressed: onLockTap,
                  ),
                  _IconActionButton(
                    icon: Icons.logout,
                    tooltip: 'Sign out',
                    onPressed: onLogoutTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportContact extends StatelessWidget {
  const _SupportContact();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.2,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.support_agent,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Call For Support', style: captionStyle),
            const SizedBox(height: 2),
            Text('+91 9032 75 73 25', style: textStyle),
          ],
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.isBusy = false,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF202124);
    final bg =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: isBusy ? null : onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: isBusy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: fg,
                ),
        ),
      ),
    );
  }
}
