// lib/features/splash/presentation/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nebourpos/core/data/secure_storage.dart';

import '../../../router/route_guards.dart';
import '../../../core/providers/core_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // small delay so splash shows and avoids jank
    await Future<void>.delayed(const Duration(milliseconds: 150));

    try {
      final store = ref.read(secureStoreProvider);
      final token = await store.read(SK.authAccessToken);
      final isLockedStr = await store.read(SK.isPasscodeRequired);
      final isLocked = (isLockedStr ?? '').toLowerCase() == 'true';

      if (!mounted) return;

      if (token == null || token.isEmpty) {
        context.go(SignInRoute.path);
        return;
      }

      if (isLocked) {
        context.go(PasscodeRoute.path);
        return;
      }

      context.go(PosRoute.path);
    } catch (_) {
      if (!mounted) return;
      context.go(SignInRoute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
