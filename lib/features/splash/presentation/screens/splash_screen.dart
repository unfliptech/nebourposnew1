import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_router.dart';
import '../../../pos/application/pos_navigation_provider.dart';
import '../providers/boot_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  ProviderSubscription<AsyncValue<BootState>>? _subscription;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual(
      bootControllerProvider,
      (previous, next) => _handleBoot(next),
    );
    // Kick off boot evaluation.
    ref.read(bootControllerProvider);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  void _handleBoot(AsyncValue<BootState> state) {
    if (!mounted) return;
    state.when(
      data: (value) {
        if (_navigated) return;
        _navigated = true;
        switch (value.target) {
          case BootTarget.signIn:
            context.go(SignInRoute.path);
            break;
          case BootTarget.passcode:
            context.go(PasscodeRoute.path);
            break;
          case BootTarget.home:
            final defaultRoute = ref.read(defaultPosRouteProvider);
            context.go(defaultRoute);
            break;
          case BootTarget.offlineBlocked:
            context.go(OfflineRoute.path);
            break;
        }
      },
      error: (error, stackTrace) {
        if (_navigated) return;
        _navigated = true;
        context.go(SignInRoute.path);
      },
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
