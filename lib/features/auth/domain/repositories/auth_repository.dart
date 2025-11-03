import '../entities/session.dart';

abstract class AuthRepository {
  Future<Session> loginWithDeviceCode(String deviceCode);

  Future<Session?> restoreSession();

  Future<void> logout();
}
