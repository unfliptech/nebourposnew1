import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/passcode_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/pos/presentation/screens/pos_shell_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/sync/presentation/screens/offline_blocked_screen.dart';
import 'route_guards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final guards = ref.watch(routeGuardsProvider);

  return GoRouter(
    initialLocation: SplashRoute.path,
    routes: [
      GoRoute(
        path: SplashRoute.path,
        name: SplashRoute.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: HomeRoute.path,
        name: HomeRoute.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: PosRoute.path,
        name: PosRoute.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: PosShellScreen(
            initialSectionKey: state.uri.queryParameters['section'],
            initialSubTypeKey: state.uri.queryParameters['subType'],
          ),
        ),
      ),
      GoRoute(
        path: SignInRoute.path,
        name: SignInRoute.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: PasscodeRoute.path,
        name: PasscodeRoute.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const PasscodeScreen(),
        ),
      ),
      GoRoute(
        path: OfflineRoute.path,
        name: OfflineRoute.name,
        pageBuilder: (context, state) => _buildTransitionPage(
          state: state,
          child: const OfflineBlockedScreen(),
        ),
      ),
    ],
    redirect: guards.redirect,
    refreshListenable: guards,
    debugLogDiagnostics: false,
  );
});

@immutable
class SplashRoute {
  const SplashRoute._();

  static const name = 'splash';
  static const path = '/';
}

@immutable
class HomeRoute {
  const HomeRoute._();

  static const name = 'home';
  static const path = '/home';
}

@immutable
class PosRoute {
  const PosRoute._();

  static const name = 'pos';
  static const path = '/pos';

  static String pathFor({String? sectionKey, String? subTypeKey}) {
    final params = <String, String>{};
    if (sectionKey != null && sectionKey.isNotEmpty) {
      params['section'] = sectionKey;
    }
    if (subTypeKey != null && subTypeKey.isNotEmpty) {
      params['subType'] = subTypeKey;
    }
    if (params.isEmpty) return path;
    return Uri(path: path, queryParameters: params).toString();
  }
}

@immutable
class SignInRoute {
  const SignInRoute._();

  static const name = 'sign-in';
  static const path = '/sign-in';
}

@immutable
class PasscodeRoute {
  const PasscodeRoute._();

  static const name = 'passcode';
  static const path = '/passcode';
}

@immutable
class OfflineRoute {
  const OfflineRoute._();

  static const name = 'offline-blocked';
  static const path = '/offline';
}

CustomTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const beginOffset = Offset(0.1, 0.0); // subtle slide from right
      const endOffset = Offset.zero;
      final slideAnimation = Tween<Offset>(begin: beginOffset, end: endOffset)
          .animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      final fadeAnimation =
          CurvedAnimation(parent: animation, curve: Curves.easeInOut);

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
    child: child,
  );
}
