import 'dart:convert';

import '../../../../../core/data/secure_storage.dart';
import '../../../../../core/data/storage_keys.dart';
import '../../models/session_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final SecureStorage _storage;

  Future<void> saveSession(SessionModel session) async {
    await _storage.write(
      StorageKeys.session,
      jsonEncode(session.toJson()),
    );
  }

  Future<SessionModel?> readSession() async {
    final raw = await _storage.read(StorageKeys.session);
    if (raw == null) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SessionModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSession() => _storage.delete(StorageKeys.session);

  Future<void> saveIdentifiers({
    required String deviceId,
    required String stationId,
    required String tenantId,
    required String deviceToken,
  }) async {
    await Future.wait([
      _storage.write(StorageKeys.posDeviceId, deviceId),
      _storage.write(StorageKeys.posStationId, stationId),
      _storage.write(StorageKeys.tenantId, tenantId),
      _storage.write(StorageKeys.posDeviceToken, deviceToken),
    ]);
  }

  Future<void> clearIdentifiers() async {
    await Future.wait([
      _storage.delete(StorageKeys.posDeviceId),
      _storage.delete(StorageKeys.posStationId),
      _storage.delete(StorageKeys.tenantId),
      _storage.delete(StorageKeys.posDeviceToken),
    ]);
  }

  Future<void> clearAuthData() async {
    await _storage.clear();
  }
}
