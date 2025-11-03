import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/data/connectivity_service.dart';
import '../core/providers/core_providers.dart';
import '../features/auth/presentation/providers/passcode_provider.dart';

final routeGuardsProvider = Provider<RouteGuards>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final guards = RouteGuards(
    connectivity: connectivity,
    ref: ref,
    passcodeRoutes: const {'/home'},
  );

  final subscription = connectivity.onStatusChange.listen((_) {
    guards.refresh();
  });

  final passcodeSubscription =
      ref.listen<PasscodeStatus>(passcodeStatusProvider, (_, __) {
    guards.refresh();
  });

  ref.onDispose(() {
    unawaited(subscription.cancel());
    passcodeSubscription.close();
    guards.dispose();
  });

  return guards;
});

class RouteGuards extends ChangeNotifier {
  RouteGuards({
    required ConnectivityService connectivity,
    required Ref ref,
    Set<String> passcodeRoutes = const {},
  })  : _connectivity = connectivity,
        _ref = ref,
        _passcodeRoutes = Set<String>.from(passcodeRoutes);

  static const _offlinePath = '/offline';
  static const _passcodePath = '/passcode';
  static const _splashPath = '/';
  static const Set<String> _onlineOnlyRoutes = {
    '/sign-in',
  };

  final ConnectivityService _connectivity;
  final Ref _ref;
  final Set<String> _passcodeRoutes;

  String? _pendingPath;
  DateTime? _pendingRecordedAt;

  String? get pendingPath => _pendingPath;
  DateTime? get pendingRecordedAt => _pendingRecordedAt;

  Future<String?> redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final location = state.matchedLocation;
    if (location == _passcodePath) {
      final status = _ref.read(passcodeStatusProvider);
      if (!status.requiresPasscode || status.isUnlocked) {
        final pending = status.pendingRoute;
        _ref.read(passcodeStatusProvider.notifier).clearPendingRoute();
        if (pending != null && pending.isNotEmpty) {
          return pending;
        }
        return _splashPath;
      }
      return null;
    }

    if (_passcodeRoutes.contains(location)) {
      final status = _ref.read(passcodeStatusProvider);
      if (status.requiresPasscode && !status.isUnlocked) {
        final target = state.uri.toString();
        final notifier = _ref.read(passcodeStatusProvider.notifier);
        if (status.pendingRoute != target) {
          notifier.setPendingRoute(target);
        }
        notifier.lock();
        return _passcodePath;
      }
    }

    if (location == _offlinePath) {
      final status = await _connectivity.checkStatus();
      if (status == ConnectivityStatus.online) {
        final target = _drainPendingTarget() ?? _splashPath;
        return target;
      }
      return null;
    }

    if (!_onlineOnlyRoutes.contains(location)) {
      return null;
    }

    final status = await _connectivity.checkStatus();
    if (status == ConnectivityStatus.online) {
      return null;
    }

    _pendingPath = state.uri.toString();
    _pendingRecordedAt = DateTime.now();
    return _offlinePath;
  }

  Future<bool> retryPending(BuildContext context) async {
    final router = GoRouter.of(context);
    final status = await _connectivity.checkStatus();
    if (status == ConnectivityStatus.offline) {
      return false;
    }
    final target = _drainPendingTarget() ?? _splashPath;
    router.go(target);
    return true;
  }

  void refresh() {
    notifyListeners();
  }

  String? _drainPendingTarget() {
    final target = _pendingPath;
    _pendingPath = null;
    _pendingRecordedAt = null;
    return target;
  }
}
