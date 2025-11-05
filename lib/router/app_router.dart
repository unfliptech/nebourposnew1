// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/shell_providers.dart';
import '../core/providers/core_providers.dart'; // <-- auth + passcode state
import '../shared/widgets/app_scaffold.dart';
import 'route_guards.dart'; // keeps only PosRoute/PasscodeRoute/SplashRoute path helpers
import '../features/splash/presentation/splash_screen.dart';
import '../features/passcode/presentation/passcode_screen.dart';
import '../dev/dev_passcode_actions.dart';

GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: SplashRoute.path,
    // Single-source redirect logic (prevents loops)
    redirect: (context, state) {
      final loc = state.matchedLocation; // v14: use matchedLocation
      final auth = ref.read(authStateProvider); // signedIn/signedOut
      final isLocked =
          ref.read(passcodeStatusProvider) == PasscodeStatus.locked;

      // 1) Splash may always run its one-shot decision
      if (loc == SplashRoute.path) return null;

      // 2) If locked, force /passcode (no loop if we're already there)
      if (isLocked) {
        if (loc != PasscodeRoute.path) return PasscodeRoute.path;
        return null;
      }

      // 3) While signed-out (dev flow, no sign-in yet), allow Home + Passcode
      if (auth == AuthState.signedOut) {
        if (loc == PosRoute.path || loc == PasscodeRoute.path) return null;
        // Any other route -> bring user to Home (or Splash if you prefer)
        return PosRoute.path;
      }

      // 4) Signed in & not locked: allow everything
      return null;
    },
    routes: [
      // Splash stands alone (no shell)
      GoRoute(
        path: SplashRoute.path,
        name: 'splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),

      // Everything else inside the app shell
      ShellRoute(
        builder: (context, state, child) => AppScaffold(body: child),
        routes: [
          GoRoute(
            path: PosRoute.path,
            name: 'home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _HomeScreen()),
          ),
          GoRoute(
            path: PasscodeRoute.path,
            name: 'passcode',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PasscodeScreen()),
          ),
        ],
      ),
    ],
    observers: [
      _TitleObserver(ref),
    ],
  );
}

class _TitleObserver extends NavigatorObserver {
  _TitleObserver(this.ref);
  final WidgetRef ref;

  @override
  void didPush(Route route, Route? previousRoute) {
    _maybeSet(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) _maybeSet(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _maybeSet(Route route) {
    final settings = route.settings;
    if (settings is Page &&
        settings.name != null &&
        settings.name!.isNotEmpty) {
      final current = ref.read(pageTitleProvider);
      if (current == 'Nebour POS') {
        ref.read(pageTitleProvider.notifier).state = settings.name!;
      }
    }
  }
}

/// Helper to set dynamic page titles from screens.
class SetPageTitle extends ConsumerStatefulWidget {
  const SetPageTitle({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  ConsumerState<SetPageTitle> createState() => _SetPageTitleState();
}

class _SetPageTitleState extends ConsumerState<SetPageTitle> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(pageTitleProvider.notifier).state = widget.title,
    );
  }

  @override
  void didUpdateWidget(covariant SetPageTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title) {
      ref.read(pageTitleProvider.notifier).state = widget.title;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return SetPageTitle(
      title: 'Home',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Nebour POS — Home'),
            SizedBox(height: 12),
            DevPasscodeActions(), // debug: set passcode & lock / lock-only
          ],
        ),
      ),
    );
  }
}
