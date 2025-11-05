// lib/router/route_guards.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';

/// Returns a redirect path or null to continue
String? authGuard(WidgetRef ref, String location) {
  final auth = ref.read(authStateProvider);

  // Standalone pages that are allowed without shell
  const allowlist = {
    SplashRoute.path,
    SignInRoute.path,
    PasscodeRoute.path,
  };

  if (auth == AuthState.signedOut) {
    if (allowlist.contains(location)) return null; // allowed
    return SignInRoute.path; // anything else => sign-in
  }
  return null; // signed-in => continue
}

String? passcodeGuard(WidgetRef ref, String location) {
  final status = ref.read(passcodeStatusProvider);
  if (status == PasscodeStatus.locked && location != PasscodeRoute.path) {
    return PasscodeRoute.path;
  }
  return null;
}

/// Simple route helpers
class PosRoute {
  static const homeName = 'home';
  static const path = '/';
  static String pathFor({String? sectionKey, String? subTypeKey}) {
    // Extend later if you add params; for now keep root
    return path;
  }
}

class PasscodeRoute {
  static const name = 'passcode';
  static const path = '/passcode';
}

class SplashRoute {
  static const name = 'splash';
  static const path = '/splash';
}

class SignInRoute {
  static const name = 'signin';
  static const path = '/signin';
}
