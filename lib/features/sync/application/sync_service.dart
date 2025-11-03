import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/connectivity_service.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/providers/passcode_provider.dart';
import '../data/datasources/remote/sync_remote_ds.dart';
import '../data/repositories/sync_repository_impl.dart';
import '../domain/mappers/sync_snapshot_mapper.dart';
import '../domain/repositories/sync_repository.dart';
import '../presentation/providers/meta_provider.dart';

enum SyncTrigger {
  startup,
  login,
  manual,
  background,
}

enum SyncOutcomeStatus {
  success,
  cached,
  offlineNoData,
  unauthenticated,
  failure,
}

class SyncOutcome {
  const SyncOutcome({
    required this.status,
    this.result,
    this.message,
    required this.wasOnline,
    required this.requiresPasscode,
  });

  final SyncOutcomeStatus status;
  final SyncResult? result;
  final String? message;
  final bool wasOnline;
  final bool requiresPasscode;

  bool get hasData => result != null;

  SyncOutcome copyWith({
    SyncOutcomeStatus? status,
    SyncResult? result,
    String? message,
    bool? wasOnline,
    bool? requiresPasscode,
  }) {
    return SyncOutcome(
      status: status ?? this.status,
      result: result ?? this.result,
      message: message ?? this.message,
      wasOnline: wasOnline ?? this.wasOnline,
      requiresPasscode: requiresPasscode ?? this.requiresPasscode,
    );
  }
}

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final metaLocal = ref.watch(metaLocalDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return SyncRepositoryImpl(
    SyncRemoteDataSource(dioClient),
    metaLocal,
    storage,
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

final lastSyncOutcomeProvider = StateProvider<SyncOutcome?>((ref) => null);

class SyncService {
  SyncService(this._ref);

  final Ref _ref;

  Future<SyncOutcome> synchronize({
    SyncTrigger trigger = SyncTrigger.manual,
  }) async {
    final connectivity = _ref.read(connectivityServiceProvider);
    final status = await connectivity.checkStatus();
    final isOnline = status == ConnectivityStatus.online;

    final metaLocal = _ref.read(metaLocalDataSourceProvider);
    final hasSnapshot = metaLocal.dataImported;

    Future<SyncOutcome> applySnapshot({
      required SyncOutcomeStatus status,
      String? message,
    }) async {
      final snapshot = metaLocal.readSnapshot();
      final domainResult = snapshot?.toDomainResult();
      final admins = domainResult?.admins ?? const <SyncAdmin>[];
      final requires = metaLocal.requiresPasscode ||
          admins.any((admin) => (admin.passcode?.isNotEmpty ?? false));
      final passcodeNotifier = _ref.read(passcodeStatusProvider.notifier);
      passcodeNotifier.configureRequirement(requires);
      return SyncOutcome(
        status: status,
        result: domainResult,
        message: message,
        wasOnline: isOnline,
        requiresPasscode: requires,
      );
    }

    if (!isOnline) {
      if (!hasSnapshot) {
        final outcome = const SyncOutcome(
          status: SyncOutcomeStatus.offlineNoData,
          wasOnline: false,
          requiresPasscode: false,
        );
        _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
        return outcome;
      }
      final outcome = await applySnapshot(status: SyncOutcomeStatus.cached);
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    }

    final authRepository = _ref.read(authRepositoryProvider);
    final session = await authRepository.restoreSession();
    if (session == null || session.isExpired) {
      final outcome = const SyncOutcome(
        status: SyncOutcomeStatus.unauthenticated,
        wasOnline: true,
        requiresPasscode: false,
      );
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    }

    try {
      final repository = _ref.read(syncRepositoryProvider);
      final result = await repository.bootstrap(session);
      final requiresPasscode = _requiresPasscode(result.features);
      final passcodeNotifier = _ref.read(passcodeStatusProvider.notifier);
      developer.log(
          'SyncService result -> features=${result.features.length}, admins=${result.admins.length}');
      passcodeNotifier.configureRequirement(requiresPasscode);
      _ref.invalidate(themeConfigProvider);
      _ref.invalidate(themeModeProvider);
      final isNotModified = result.status.toLowerCase() == 'not_modified';
      final outcomeStatus =
          isNotModified ? SyncOutcomeStatus.cached : SyncOutcomeStatus.success;
      final outcomeMessage = isNotModified ? 'Already up to date' : null;
      final outcome = SyncOutcome(
        status: outcomeStatus,
        result: result,
        message: outcomeMessage,
        wasOnline: true,
        requiresPasscode: requiresPasscode,
      );
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    } on LoggedOutException {
      await _ref.read(authControllerProvider.notifier).logout();
      final outcome = const SyncOutcome(
        status: SyncOutcomeStatus.unauthenticated,
        wasOnline: true,
        requiresPasscode: false,
      );
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    } on SyncFailureException catch (error) {
      if (hasSnapshot) {
        final outcome = await applySnapshot(
          status: SyncOutcomeStatus.cached,
          message: error.message,
        );
        _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
        return outcome;
      }
      final outcome = SyncOutcome(
        status: SyncOutcomeStatus.failure,
        message: error.message,
        wasOnline: true,
        requiresPasscode: false,
      );
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    } on DioException catch (error) {
      if (_isAuthError(error)) {
        await _ref.read(authControllerProvider.notifier).logout();
        final outcome = const SyncOutcome(
          status: SyncOutcomeStatus.unauthenticated,
          wasOnline: true,
          requiresPasscode: false,
        );
        _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
        return outcome;
      }
      final message = _resolveErrorMessage(error);
      if (hasSnapshot) {
        final outcome = await applySnapshot(
          status: SyncOutcomeStatus.cached,
          message: message,
        );
        _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
        return outcome;
      }
      final outcome = SyncOutcome(
        status: SyncOutcomeStatus.failure,
        message: message,
        wasOnline: true,
        requiresPasscode: false,
      );
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    } catch (error) {
      if (hasSnapshot) {
        final outcome = await applySnapshot(
          status: SyncOutcomeStatus.cached,
          message: error.toString(),
        );
        _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
        return outcome;
      }
      final outcome = SyncOutcome(
        status: SyncOutcomeStatus.failure,
        message: error.toString(),
        wasOnline: true,
        requiresPasscode: false,
      );
      _ref.read(lastSyncOutcomeProvider.notifier).state = outcome;
      return outcome;
    }
  }

  bool _requiresPasscode(List<SyncFeature> features) {
    for (final feature in features) {
      if (feature.key.toUpperCase() == 'REQUIRE_PASSCODE' &&
          (feature.enabled ?? false)) {
        return true;
      }
    }
    return false;
  }

  bool _isAuthError(DioException exception) {
    final statusCode = exception.response?.statusCode;
    return statusCode == 401 || statusCode == 403;
  }

  String _resolveErrorMessage(DioException error) {
    final response = error.response;
    final data = response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return errors.values.first.toString();
      }
    }
    return error.message ?? 'Sync failed. Please try again.';
  }
}
