import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/secure_storage.dart';

/// Singletons / app-wide services
final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

/// -------- Auth state (set by Splash) --------
enum AuthState { signedOut, signedIn }

final authStateProvider = StateProvider<AuthState>((_) => AuthState.signedOut);

/// Helper: holds the last route we wanted when lock engaged
final pendingRouteProvider = StateProvider<String>((_) => '/');

/// -------- Passcode lock state --------
enum PasscodeStatus { locked, unlocked }

class PasscodeStatusNotifier extends StateNotifier<PasscodeStatus> {
  PasscodeStatusNotifier(this.ref) : super(PasscodeStatus.unlocked);

  final Ref ref;

  void lock({required String pendingRoute}) {
    ref.read(pendingRouteProvider.notifier).state = pendingRoute;
    state = PasscodeStatus.locked;
  }

  void unlock() {
    state = PasscodeStatus.unlocked;
  }
}

final passcodeStatusProvider =
    StateNotifierProvider<PasscodeStatusNotifier, PasscodeStatus>(
  (ref) => PasscodeStatusNotifier(ref),
);
