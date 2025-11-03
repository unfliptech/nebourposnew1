import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/logger.dart';
import '../data/connectivity_service.dart';
import '../data/dio_client.dart';
import '../data/env.dart';
import '../data/isar_service.dart';
import '../data/secure_storage.dart';
import '../data/storage_keys.dart';
import '../data/theme.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);

  Future<String?> authHeaderProvider() async {
    final raw = await storage.read(StorageKeys.session);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final token = data['access_token']?.toString();
      if (token == null || token.isEmpty) {
        return null;
      }
      final type = data['token_type']?.toString().trim();
      if (type != null && type.isNotEmpty) {
        return '$type $token';
      }
      return 'Bearer $token';
    } catch (_) {
      return null;
    }
  }

  return DioClient(
    baseUrl: Env.apiBase,
    authHeaderProvider: authHeaderProvider,
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isarServiceProvider = Provider<IsarService>((ref) {
  return IsarService.instance;
});

final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  return ThemeRepository(ref.watch(secureStorageProvider));
});

final connectivityStatusProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.checkStatus();
  yield* service.onStatusChange;
});

Future<List<Override>> createCoreOverrides() async {
  return <Override>[];
}

class LoggerProviderObserver extends ProviderObserver {
  const LoggerProviderObserver();

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value,
      ProviderContainer container) {
    Logger.debug('Provider added', provider: provider, value: value);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    Logger.debug(
      'Provider updated',
      provider: provider,
      value: newValue,
      previousValue: previousValue,
    );
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    Logger.debug('Provider disposed', provider: provider);
  }
}
