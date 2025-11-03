import '../../domain/entities/session.dart';

class SessionModel extends Session {
  SessionModel({
    required super.accessToken,
    required super.expiresAt,
    required super.deviceId,
    required super.stationId,
    required super.tenantId,
    required super.tokenType,
    required super.deviceToken,
    super.deviceName,
    super.platform,
    super.osVersion,
    super.appVersion,
    super.manufacturer,
    super.modelName,
    super.posMode,
    super.adminId,
    super.adminName,
  });

  factory SessionModel.fromApi(
    Map<String, dynamic> payload, {
    DateTime? receivedAt,
  }) {
    final device = (payload['device'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final expiresInRaw = payload['expires_in'];
    final expiresIn = _parseExpiresIn(expiresInRaw);
    final now = (receivedAt ?? DateTime.now()).toUtc();
    final expiresAt = expiresIn != null && expiresIn > 0
        ? now.add(Duration(seconds: expiresIn))
        : now.add(const Duration(days: 365 * 5));

    final accessToken = payload['access_token']?.toString();
    final tokenType = payload['token_type']?.toString() ?? 'Bearer';
    final deviceId = (payload['device_id'] ??
            device['id'] ??
            payload['device_token'] ??
            device['device_token'])
        ?.toString();
    final deviceToken =
        (payload['device_token'] ?? device['device_token'])?.toString();
    final tenantId =
        (payload['tenant_id'] ?? device['tenant_id'])?.toString();
    final branchId = (payload['branch_id'] ??
            payload['station_id'] ??
            device['branch_id'] ??
            device['station_id'])
        ?.toString();

    if (accessToken == null ||
        deviceId == null ||
        deviceToken == null ||
        tenantId == null ||
        branchId == null) {
      throw const FormatException('Incomplete auth response');
    }

    return SessionModel(
      accessToken: accessToken,
      expiresAt: expiresAt,
      deviceId: deviceId,
      stationId: branchId,
      tenantId: tenantId,
      tokenType: tokenType,
      deviceToken: deviceToken,
      deviceName:
          (payload['device_name'] ?? device['name'])?.toString(),
      platform:
          (payload['platform'] ?? device['platform'])?.toString(),
      osVersion:
          (payload['os_version'] ?? device['os_version'])?.toString(),
      appVersion:
          (payload['app_version'] ?? device['app_version'])?.toString(),
      manufacturer: (payload['manufacturer'] ?? device['manufacturer'])
          ?.toString(),
      modelName:
          (payload['model_name'] ?? device['model_name'])?.toString(),
      posMode:
          (payload['pos_mode'] ?? device['pos_mode'])?.toString(),
    );
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('refresh_token')) {
      // Legacy session payload support.
      final admin = json['admin'] as Map<String, dynamic>?;
      final expiresAtRaw = json['expires_at']?.toString();
      final expiresAt = DateTime.tryParse(expiresAtRaw ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return SessionModel(
        accessToken: json['access_token']?.toString() ?? '',
        expiresAt: expiresAt.toUtc(),
        deviceId: json['device_id']?.toString() ?? '',
        stationId: json['station_id']?.toString() ?? '',
        tenantId: json['tenant_id']?.toString() ?? '',
        tokenType: json['token_type']?.toString() ?? 'Bearer',
        deviceToken: json['device_token']?.toString() ?? '',
        adminId: admin?['id'] as String?,
        adminName: admin?['name'] as String?,
        deviceName: json['device_name']?.toString(),
        platform: json['platform']?.toString(),
        osVersion: json['os_version']?.toString(),
        appVersion: json['app_version']?.toString(),
        manufacturer: json['manufacturer']?.toString(),
        modelName: json['model_name']?.toString(),
        posMode: json['pos_mode']?.toString(),
      );
    }

    final admin = json['admin'] as Map<String, dynamic>?;
    final device = json['device'] as Map<String, dynamic>? ?? const {};
    final expiresAtRaw = json['expires_at']?.toString();
    final expiresIn = _parseExpiresIn(json['expires_in']);
    DateTime expiresAt;
    if (expiresAtRaw != null) {
      expiresAt = DateTime.parse(expiresAtRaw).toUtc();
    } else {
      final now = DateTime.now().toUtc();
      expiresAt = expiresIn != null && expiresIn > 0
          ? now.add(Duration(seconds: expiresIn))
          : now.add(const Duration(days: 365 * 5));
    }

    return SessionModel(
      accessToken: json['access_token']?.toString() ?? '',
      expiresAt: expiresAt,
      deviceId: json['device_id']?.toString() ?? device['id']?.toString() ?? '',
      stationId: json['station_id']?.toString() ??
          json['branch_id']?.toString() ??
          device['branch_id']?.toString() ??
          '',
      tenantId: json['tenant_id']?.toString() ??
          device['tenant_id']?.toString() ??
          '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      deviceToken: json['device_token']?.toString() ??
          device['device_token']?.toString() ??
          '',
      adminId: admin?['id'] as String?,
      adminName: admin?['name'] as String?,
      deviceName: json['device_name']?.toString() ?? device['name']?.toString(),
      platform: json['platform']?.toString() ?? device['platform']?.toString(),
      osVersion:
          json['os_version']?.toString() ?? device['os_version']?.toString(),
      appVersion:
          json['app_version']?.toString() ?? device['app_version']?.toString(),
      manufacturer: json['manufacturer']?.toString() ??
          device['manufacturer']?.toString(),
      modelName:
          json['model_name']?.toString() ?? device['model_name']?.toString(),
      posMode: json['pos_mode']?.toString() ?? device['pos_mode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'access_token': accessToken,
      'expires_at': expiresAt.toIso8601String(),
      'device_id': deviceId,
      'station_id': stationId,
      'branch_id': stationId,
      'tenant_id': tenantId,
      'token_type': tokenType,
      'device_token': deviceToken,
      if (deviceName != null) 'device_name': deviceName,
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'os_version': osVersion,
      if (appVersion != null) 'app_version': appVersion,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (modelName != null) 'model_name': modelName,
      if (posMode != null) 'pos_mode': posMode,
    };
    if (adminId != null || adminName != null) {
      data['admin'] = {
        if (adminId != null) 'id': adminId,
        if (adminName != null) 'name': adminName,
      };
    }
    return data;
  }

  static int? _parseExpiresIn(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final parsed = int.tryParse(value.toString());
    return parsed;
  }
}
