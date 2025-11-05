// lib/dev/dev_passcode_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/secure_storage.dart';
import '../core/providers/core_providers.dart';
import '../router/route_guards.dart';

/// Call this anywhere to persist a test passcode and require it on startup.
Future<void> requirePasscodeOnStartup(WidgetRef ref,
    {String code = '1234'}) async {
  final store = ref.read(secureStoreProvider);
  await store.write(SK.isPasscodeRequired, 'true');
  await store.write(SK.passcodeValue, code);
}

/// Call this to immediately show the passcode screen (no restart needed).
void lockNow(BuildContext context, WidgetRef ref,
    {String pending = PosRoute.path}) {
  ref.read(passcodeStatusProvider.notifier).lock(pendingRoute: pending);
  context.go(PasscodeRoute.path);
}

/// Debug UI you can place on any screen to trigger the behavior.
class DevPasscodeActions extends ConsumerWidget {
  const DevPasscodeActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () async {
            await requirePasscodeOnStartup(ref, code: '1234');
            if (context.mounted) lockNow(context, ref, pending: PosRoute.path);
          },
          child: const Text('Set Passcode & Lock Now'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => lockNow(context, ref, pending: PosRoute.path),
          child: const Text('Lock Now (no persist)'),
        ),
      ],
    );
  }
}
