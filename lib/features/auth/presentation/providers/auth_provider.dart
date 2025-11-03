import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sync/application/sync_service.dart';
import '../../../sync/presentation/providers/meta_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';
import 'passcode_provider.dart';
import '../../data/datasources/local/auth_local_ds.dart';
import '../../data/datasources/remote/auth_remote_ds.dart';
import '../../data/models/session_model.dart';
import '../../data/services/device_info_service.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';

final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  final deviceInfo = ref.watch(deviceInfoServiceProvider);
  return _AuthRepositoryImpl(
    AuthRemoteDataSource(dioClient),
    AuthLocalDataSource(storage),
    deviceInfo,
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, Session?>(AuthController.new);

class AuthController extends AsyncNotifier<Session?> {
  @override
  FutureOr<Session?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    return repository.restoreSession();
  }

  Future<void> login(String deviceCode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.loginWithDeviceCode(deviceCode);
      await ref.read(metaLocalDataSourceProvider).clear();
      await ref.read(isarServiceProvider).clearAll();
      ref.invalidate(themeConfigProvider);
      ref.invalidate(themeModeProvider);
      ref.read(passcodeStatusProvider.notifier).reset();
      final syncOutcome = await ref
          .read(syncServiceProvider)
          .synchronize(trigger: SyncTrigger.login);
      switch (syncOutcome.status) {
        case SyncOutcomeStatus.success:
        case SyncOutcomeStatus.cached:
          if (syncOutcome.hasData) {
            ref.invalidate(homeProvider);
          }
          break;
        case SyncOutcomeStatus.failure:
        case SyncOutcomeStatus.offlineNoData:
          throw Exception(
            syncOutcome.message ?? 'Sync failed. Please try again.',
          );
        case SyncOutcomeStatus.unauthenticated:
          throw Exception('Session expired. Please log in again.');
      }
      return session;
    });
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    await ref.read(metaLocalDataSourceProvider).clear();
    await ref.read(isarServiceProvider).clearAll();
    ref.invalidate(themeConfigProvider);
    ref.invalidate(themeModeProvider);
    ref.read(passcodeStatusProvider.notifier).reset();
    ref.invalidate(homeProvider);
    state = const AsyncValue.data(null);
  }
}

class _AuthRepositoryImpl implements AuthRepository {
  _AuthRepositoryImpl(this._remote, this._local, this._deviceInfo);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final DeviceInfoService _deviceInfo;
  SessionModel? _cache;

  @override
  Future<Session> loginWithDeviceCode(String deviceCode) async {
    try {
      final payload = await _deviceInfo.buildRegistrationPayload(deviceCode);
      final session = await _remote.registerDevice(payload);
      await _persistSession(session);
      return session;
    } on DioException catch (error) {
      throw _resolveErrorMessage(error);
    }
  }

  @override
  Future<Session?> restoreSession() async {
    _cache ??= await _local.readSession();
    return _cache;
  }

  @override
  Future<void> logout() async {
    final session = await restoreSession();
    if (session != null) {
      try {
        await _remote.logoutDevice(session);
      } catch (_) {
        // Ignore remote logout failures; proceed with local cleanup.
      }
    }
    await _local.clearAuthData();
    _cache = null;
  }

  Future<void> _persistSession(SessionModel session) async {
    await _local.clearAuthData();
    _cache = session;
    await _local.saveSession(session);
    await _local.saveIdentifiers(
      deviceId: session.deviceId,
      stationId: session.stationId,
      tenantId: session.tenantId,
      deviceToken: session.deviceToken,
    );
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
    return error.message ?? 'Unable to register device';
  }
}
