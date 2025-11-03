import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/providers/home_provider.dart';
import '../../application/sync_service.dart';

enum AutoSyncStatus {
  idle,
  syncing,
  success,
  error,
}

class AutoSyncState {
  const AutoSyncState({
    required this.status,
    this.lastOutcome,
    this.lastStartedAt,
    this.lastCompletedAt,
    this.lastMessage,
    this.lastError,
    this.nextRunAt,
  });

  final AutoSyncStatus status;
  final SyncOutcomeStatus? lastOutcome;
  final DateTime? lastStartedAt;
  final DateTime? lastCompletedAt;
  final String? lastMessage;
  final String? lastError;
  final DateTime? nextRunAt;

  AutoSyncState copyWith({
    AutoSyncStatus? status,
    SyncOutcomeStatus? lastOutcome,
    DateTime? lastStartedAt,
    DateTime? lastCompletedAt,
    DateTime? nextRunAt,
    String? lastMessage,
    bool updateMessage = false,
    String? lastError,
    bool updateError = false,
  }) {
    return AutoSyncState(
      status: status ?? this.status,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      lastStartedAt: lastStartedAt ?? this.lastStartedAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastMessage: updateMessage ? lastMessage : this.lastMessage,
      lastError: updateError ? lastError : this.lastError,
    );
  }

  static AutoSyncState initial({DateTime? nextRunAt}) {
    return AutoSyncState(
      status: AutoSyncStatus.idle,
      nextRunAt: nextRunAt,
    );
  }
}

final autoSyncControllerProvider =
    AutoDisposeNotifierProvider<AutoSyncController, AutoSyncState>(
  AutoSyncController.new,
);

class AutoSyncController extends AutoDisposeNotifier<AutoSyncState> {
  static const _interval = Duration(minutes: 2);

  Timer? _timer;
  bool _isSyncing = false;
  bool _disposed = false;

  @override
  AutoSyncState build() {
    ref.onDispose(_stopTimer);
    _disposed = false;
    final initialState = AutoSyncState.initial(
      nextRunAt: DateTime.now().add(_interval),
    );
    _startTimer(runImmediately: true);
    return initialState;
  }

  Future<SyncOutcome?> triggerNow() {
    return _runAutoSync();
  }

  Future<SyncOutcome?> runManualSync() {
    return _runAutoSync(trigger: SyncTrigger.manual);
  }

  void _startTimer({bool runImmediately = false}) {
    _timer?.cancel();
    _timer = Timer.periodic(
      _interval,
      (_) => unawaited(_runAutoSync()),
    );
    if (runImmediately) {
      Future<void>.microtask(() {
        if (_disposed) return;
        unawaited(_runAutoSync());
      });
    }
  }

  Future<SyncOutcome?> _runAutoSync(
      {SyncTrigger trigger = SyncTrigger.background}) async {
    if (_isSyncing || _disposed) {
      return null;
    }
    _isSyncing = true;
    final startedAt = DateTime.now();
    _emit(
      (current) => current.copyWith(
        status: AutoSyncStatus.syncing,
        lastStartedAt: startedAt,
        updateMessage: true,
        lastMessage: null,
        updateError: true,
        lastError: null,
      ),
    );

    try {
      final outcome =
          await ref.read(syncServiceProvider).synchronize(trigger: trigger);

      if (_disposed) {
        return outcome;
      }
      if (outcome.hasData) {
        ref.invalidate(homeProvider);
      }

      final completedAt = DateTime.now();
      _emit(
        (current) => current.copyWith(
          status: _mapOutcomeToStatus(outcome.status, outcome.hasData),
          lastOutcome: outcome.status,
          lastCompletedAt: completedAt,
          nextRunAt: completedAt.add(_interval),
          updateMessage: true,
          lastMessage: outcome.message,
          updateError: true,
          lastError: null,
        ),
      );
      return outcome;
    } catch (error) {
      if (_disposed) {
        return null;
      }
      final completedAt = DateTime.now();
      _emit(
        (current) => current.copyWith(
          status: AutoSyncStatus.error,
          lastOutcome: SyncOutcomeStatus.failure,
          lastCompletedAt: completedAt,
          nextRunAt: completedAt.add(_interval),
          updateMessage: true,
          lastMessage: null,
          updateError: true,
          lastError: error.toString(),
        ),
      );
      return null;
    } finally {
      _isSyncing = false;
    }
  }

  void _stopTimer() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  void _emit(
    AutoSyncState Function(AutoSyncState current) transform,
  ) {
    if (_disposed) {
      return;
    }
    state = transform(state);
  }

  AutoSyncStatus _mapOutcomeToStatus(
    SyncOutcomeStatus outcome,
    bool hasData,
  ) {
    switch (outcome) {
      case SyncOutcomeStatus.success:
      case SyncOutcomeStatus.cached:
        return AutoSyncStatus.success;
      case SyncOutcomeStatus.offlineNoData:
      case SyncOutcomeStatus.unauthenticated:
        return hasData ? AutoSyncStatus.success : AutoSyncStatus.error;
      case SyncOutcomeStatus.failure:
        return AutoSyncStatus.error;
    }
  }
}
