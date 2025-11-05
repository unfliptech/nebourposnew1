import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/shell_providers.dart';

class AppHeaderBar extends ConsumerWidget {
  const AppHeaderBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final title = ref.watch(pageTitleProvider);
    final isDark = theme.brightness == Brightness.dark;
    final logoAsset =
        isDark ? 'assets/nebour-logo-dark.png' : 'assets/nebour-logo-light.png';

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Image.asset(logoAsset,
              height: 22,
              fit:
                  BoxFit.contain), // TODO: Add actions (sync, lock, user) later
        ],
      ),
    );
  }
}
