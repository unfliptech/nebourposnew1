import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../router/app_router.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../providers/auth_provider.dart';
import '../providers/passcode_provider.dart';
import '../../../sync/presentation/providers/meta_provider.dart';
import '../../../sync/domain/mappers/sync_snapshot_mapper.dart';
import '../../../pos/application/pos_navigation_provider.dart';

class PasscodeScreen extends ConsumerStatefulWidget {
  const PasscodeScreen({super.key});

  @override
  ConsumerState<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends ConsumerState<PasscodeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _navigated = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Unified key handler (desktop / web / numpad)
  KeyEventResult _handleKeyPress(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // --- Handle backspace
    if (key == LogicalKeyboardKey.backspace) {
      if (_controller.text.isNotEmpty) {
        setState(() {
          _controller.text =
              _controller.text.substring(0, _controller.text.length - 1);
        });
      }
      return KeyEventResult.handled;
    }

    // --- Handle Enter / NumpadEnter
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _validate(_controller.text);
      return KeyEventResult.handled;
    }

    // --- Handle digits (main row and numpad)
    final numpadKeys = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    String? digit;
    if (RegExp(r'^[0-9]$').hasMatch(key.keyLabel)) {
      digit = key.keyLabel;
    } else if (numpadKeys.containsKey(key)) {
      digit = numpadKeys[key];
    }

    if (digit != null) {
      if (_controller.text.length < 4) {
        setState(() => _controller.text += digit!);

        // 🔥 Delay validation to next frame to ensure all dots render
        if (_controller.text.length + 1 == 4) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _validate(_controller.text);
          });
        }
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final passcodeState = ref.watch(passcodeControllerProvider);
    final passcodeStatus = ref.watch(passcodeStatusProvider);
    final defaultRoute = ref.watch(defaultPosRouteProvider);

    // --- Contextual branch info ---
    final syncSnapshot = ref.watch(metaLocalDataSourceProvider).readSnapshot();
    final syncResult = syncSnapshot?.toDomainResult();
    final tenantName = syncResult?.tenant?.name ?? 'Tenant';
    final branchName = syncResult?.branch?.name ?? 'Branch';
    final branchCode = syncResult?.branch?.code ?? 'Code';

    // --- Redirect if no session ---
    authState.whenOrNull(
      data: (session) {
        if (session == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go(SignInRoute.path);
          });
        }
      },
    );

    // --- Auto-navigate if unlocked ---
    if ((!passcodeStatus.requiresPasscode || passcodeStatus.isUnlocked) &&
        !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _navigated) return;
        final pending = passcodeStatus.pendingRoute ?? defaultRoute;
        ref.read(passcodeStatusProvider.notifier).clearPendingRoute();
        _navigated = true;
        context.go(pending);
      });
    }

    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    // --- Custom draggable app bar ---
    final appBar = AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            theme.brightness == Brightness.dark
                ? 'assets/nebour-logo-dark.png'
                : 'assets/nebour-logo-light.png',
            width: 140,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$tenantName | $branchName',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                branchCode,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final PreferredSizeWidget effectiveAppBar = isDesktop
        ? PreferredSize(
            preferredSize: appBar.preferredSize,
            child: DragToMoveArea(child: appBar),
          )
        : appBar;

    // --- Main body ---
    return AppScaffold(
      appBar: effectiveAppBar,
      body: Focus(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: _handleKeyPress,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Unlock the POS with your 4-digit passcode.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _PasscodeDots(
                  length: _controller.text.length,
                  total: 4,
                  fillColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 40),
                _Numpad(
                  onNumberTap: (digit) {
                    if (_controller.text.length < 4) {
                      setState(() => _controller.text += digit);

                      if (_controller.text.length + 1 == 4) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _validate(_controller.text);
                        });
                      }
                    }
                  },
                  onDelete: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        _controller.text = _controller.text
                            .substring(0, _controller.text.length - 1);
                      });
                    }
                  },
                  onEnter: () => _validate(_controller.text),
                  isDisabled: passcodeState.isValidating,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: SizedBox(
                    key: ValueKey(passcodeState.error),
                    height: 24,
                    child: Center(
                      child: Text(
                        passcodeState.error ?? '',
                        style: TextStyle(
                          color: passcodeState.error != null
                              ? theme.colorScheme.error
                              : Colors.transparent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _validate(String value) async {
    if (value.length != 4) return;

    final status = ref.read(passcodeStatusProvider);
    final defaultRoute = ref.read(defaultPosRouteProvider);
    final success =
        await ref.read(passcodeControllerProvider.notifier).verify(value);

    if (success && mounted) {
      _controller.clear();
      final pending = status.pendingRoute ?? defaultRoute;
      ref.read(passcodeStatusProvider.notifier).unlock();
      _navigated = true;
      context.go(pending);
    } else {
      _controller.clear();
      HapticFeedback.mediumImpact();
      setState(() {});
    }
  }
}

// --- Passcode dots ---
class _PasscodeDots extends StatelessWidget {
  const _PasscodeDots({
    required this.length,
    required this.total,
    required this.fillColor,
  });

  final int length;
  final int total;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final filled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: fillColor, width: 2),
            color: filled ? fillColor : Colors.transparent,
          ),
        );
      }),
    );
  }
}

// --- Numpad ---
class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.onNumberTap,
    required this.onDelete,
    required this.onEnter,
    required this.isDisabled,
  });

  final void Function(String) onNumberTap;
  final VoidCallback onDelete;
  final VoidCallback onEnter;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double gap = 20;

    Widget buildButton(
      String label, {
      VoidCallback? onTap,
      IconData? icon,
      bool isPrimary = false,
    }) {
      return Padding(
        padding: const EdgeInsets.all(gap / 2),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              border: Border.all(
                color: isPrimary
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withAlpha(100),
                width: 1,
              ),
            ),
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      size: 26,
                      color: isPrimary
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map((label) =>
                    buildButton(label, onTap: () => onNumberTap(label)))
                .toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton('', icon: Icons.backspace_outlined, onTap: onDelete),
            buildButton('0', onTap: () => onNumberTap('0')),
            buildButton('', icon: Icons.check, isPrimary: true, onTap: onEnter),
          ],
        ),
      ],
    );
  }
}
