import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/connectivity_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/domain/entities/session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/passcode_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../sync/application/sync_service.dart';
import '../../../sync/domain/repositories/sync_repository.dart';
import 'package:nebourpos2/features/pos/application/pos_navigation_provider.dart';

enum BootTarget {
  signIn,
  passcode,
  home,
  offlineBlocked,
}

class BootState {
  const BootState({
    required this.target,
    this.session,
    this.isOffline = false,
  });

  final BootTarget target;
  final Session? session;
  final bool isOffline;
}

final bootControllerProvider =
    AsyncNotifierProvider<BootController, BootState>(BootController.new);

class BootController extends AsyncNotifier<BootState> {
  @override
  FutureOr<BootState> build() async {
    final connectivity = ref.watch(connectivityServiceProvider);
    final status = await connectivity.checkStatus();
    final isOnline = status == ConnectivityStatus.online;

    final authRepository = ref.watch(authRepositoryProvider);
    final session = await authRepository.restoreSession();

    if (session == null || session.isExpired) {
      return BootState(
        target: BootTarget.signIn,
        isOffline: !isOnline,
      );
    }

    final syncService = ref.read(syncServiceProvider);
    final outcome = await syncService.synchronize(trigger: SyncTrigger.startup);

    if (outcome.hasData) {
      ref.invalidate(homeProvider);
    }

    if (outcome.status == SyncOutcomeStatus.offlineNoData) {
      return BootState(
        target: BootTarget.offlineBlocked,
        session: session,
        isOffline: true,
      );
    }

    if (outcome.status == SyncOutcomeStatus.unauthenticated) {
      return BootState(
        target: BootTarget.signIn,
        isOffline: !isOnline,
      );
    }

    final passcodeStatus = ref.read(passcodeStatusProvider);
    final defaultRoute = ref.read(defaultPosRouteProvider);
    final requiresPasscode = outcome.requiresPasscode ||
        passcodeStatus.requiresPasscode ||
        ((outcome.result?.admins ?? const <SyncAdmin>[]).isNotEmpty);

    ref.read(passcodeStatusProvider.notifier).configureRequirement(
          requiresPasscode,
          lock: requiresPasscode,
          pendingRoute: defaultRoute,
        );

    if (requiresPasscode) {
      return BootState(
        target: BootTarget.passcode,
        session: session,
        isOffline: !isOnline,
      );
    }

    if (outcome.status == SyncOutcomeStatus.failure && !outcome.hasData) {
      return BootState(
        target: BootTarget.signIn,
        session: session,
        isOffline: !isOnline,
      );
    }

    if (passcodeStatus.requiresPasscode && !passcodeStatus.isUnlocked) {
      return BootState(
        target: BootTarget.passcode,
        session: session,
        isOffline: !isOnline,
      );
    }

    return BootState(
      target: BootTarget.home,
      session: session,
      isOffline: !isOnline,
    );
  }
}
