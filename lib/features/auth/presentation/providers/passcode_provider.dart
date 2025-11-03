import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/secure_storage.dart';
import '../../../../core/data/storage_keys.dart';
import '../../../../core/providers/core_providers.dart';

class PasscodeStatus {
  const PasscodeStatus({
    required this.requiresPasscode,
    required this.isUnlocked,
    this.pendingRoute,
  });

  final bool requiresPasscode;
  final bool isUnlocked;
  final String? pendingRoute;

  static const initial = PasscodeStatus(
    requiresPasscode: false,
    isUnlocked: true,
    pendingRoute: null,
  );

  bool get isLocked => requiresPasscode && !isUnlocked;

  PasscodeStatus copyWith({
    bool? requiresPasscode,
    bool? isUnlocked,
    String? pendingRoute,
    bool clearPendingRoute = false,
  }) {
    return PasscodeStatus(
      requiresPasscode: requiresPasscode ?? this.requiresPasscode,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      pendingRoute: clearPendingRoute
          ? null
          : (pendingRoute ?? this.pendingRoute),
    );
  }
}

class PasscodeState {
  const PasscodeState({
    this.isValidating = false,
    this.error,
    this.attempts = 0,
  });

  final bool isValidating;
  final String? error;
  final int attempts;

  PasscodeState copyWith({
    bool? isValidating,
    String? error,
    int? attempts,
  }) {
    return PasscodeState(
      isValidating: isValidating ?? this.isValidating,
      error: error,
      attempts: attempts ?? this.attempts,
    );
  }
}

final passcodeStatusProvider =
    StateNotifierProvider<PasscodeStatusNotifier, PasscodeStatus>(
  (ref) => PasscodeStatusNotifier(),
);

class PasscodeStatusNotifier extends StateNotifier<PasscodeStatus> {
  PasscodeStatusNotifier() : super(PasscodeStatus.initial);

  void configureRequirement(
    bool requires, {
    bool lock = false,
    String? pendingRoute,
  }) {
    if (!requires) {
      state = PasscodeStatus.initial;
      return;
    }
    final shouldLock = lock || !state.requiresPasscode;
    final next = state.copyWith(
      requiresPasscode: true,
      isUnlocked: shouldLock ? false : state.isUnlocked,
      pendingRoute: pendingRoute ?? state.pendingRoute,
    );
    if (identical(state, next) ||
        (state.requiresPasscode == next.requiresPasscode &&
            state.isUnlocked == next.isUnlocked &&
            state.pendingRoute == next.pendingRoute)) {
      return;
    }
    state = next;
  }

  void unlock() {
    if (state.isUnlocked && state.pendingRoute == null) {
      return;
    }
    state = state.copyWith(
      isUnlocked: true,
      clearPendingRoute: true,
    );
  }

  void lock({String? pendingRoute}) {
    final target = pendingRoute ?? state.pendingRoute;
    if (!state.isUnlocked && state.pendingRoute == target) {
      return;
    }
    state = state.copyWith(
      isUnlocked: false,
      pendingRoute: target,
    );
  }

  void setPendingRoute(String? route) {
    if (state.pendingRoute == route) {
      return;
    }
    state = state.copyWith(pendingRoute: route);
  }

  void clearPendingRoute() {
    if (state.pendingRoute == null) {
      return;
    }
    state = state.copyWith(clearPendingRoute: true);
  }

  void reset() {
    state = PasscodeStatus.initial;
  }
}

final passcodeControllerProvider =
    AutoDisposeNotifierProvider<PasscodeController, PasscodeState>(
  PasscodeController.new,
);

class PasscodeController extends AutoDisposeNotifier<PasscodeState> {
  late final SecureStorage _storage;

  @override
  PasscodeState build() {
    _storage = ref.watch(secureStorageProvider);
    return const PasscodeState();
  }

  Future<bool> verify(String passcode) async {
    state = state.copyWith(isValidating: true, error: null);
    final stored = await _storage.read(StorageKeys.adminPasscode);
    state = state.copyWith(isValidating: false);
    if (stored == null || stored.isEmpty) {
      state = state.copyWith(error: 'Passcode not set. Please sync data.');
      return false;
    }
    if (stored != passcode) {
      state = state.copyWith(
        error: 'Incorrect passcode',
        attempts: state.attempts + 1,
      );
      return false;
    }
    state = const PasscodeState();
    return true;
  }
}
