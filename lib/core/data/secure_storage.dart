import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Canonical secure storage keys
class SK {
  // Auth
  static const authAccessToken = 'auth.access_token';
  static const authTokenType = 'auth.token_type';
  static const authExpiresAt = 'auth.expires_at';
  static const tenantId = 'auth.tenant_id';
  static const branchId = 'auth.branch_id';

  // Device
  static const deviceToken = 'device.device_token';
  static const devicePosMode = 'device.pos_mode';
  static const deviceInputType = 'device.input_type';

  // Security
  static const isPasscodeRequired =
      'security.is_passcode_required'; // "true" | "false"
  static const passcodeHint = 'security.passcode_hint';
  static const passcodeValue = 'security.passcode_value'; // <-- NEW

  // Sync
  static const lastSyncedAt = 'sync.last_synced_at';
}

class SecureStore {
  SecureStore([FlutterSecureStorage? impl])
      : _impl = impl ?? const FlutterSecureStorage();

  final FlutterSecureStorage _impl;

  Future<void> write(String key, String value) =>
      _impl.write(key: key, value: value);

  Future<String?> read(String key) => _impl.read(key: key);

  Future<void> delete(String key) => _impl.delete(key: key);

  Future<void> deleteAll() => _impl.deleteAll();
}
