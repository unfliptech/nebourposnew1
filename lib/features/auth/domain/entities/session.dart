class Session {
  const Session({
    required this.accessToken,
    required this.expiresAt,
    required this.deviceId,
    required this.stationId,
    required this.tenantId,
    required this.tokenType,
    required this.deviceToken,
    this.deviceName,
    this.platform,
    this.osVersion,
    this.appVersion,
    this.manufacturer,
    this.modelName,
    this.posMode,
    this.adminId,
    this.adminName,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String deviceId;
  final String stationId;
  final String tenantId;
  final String tokenType;
  final String deviceToken;
  final String? deviceName;
  final String? platform;
  final String? osVersion;
  final String? appVersion;
  final String? manufacturer;
  final String? modelName;
  final String? posMode;
  final String? adminId;
  final String? adminName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeToExpiry => expiresAt.difference(DateTime.now());

  Session copyWith({
    String? accessToken,
    DateTime? expiresAt,
    String? deviceId,
    String? stationId,
    String? tenantId,
    String? tokenType,
    String? deviceToken,
    String? deviceName,
    String? platform,
    String? osVersion,
    String? appVersion,
    String? manufacturer,
    String? modelName,
    String? posMode,
    String? adminId,
    String? adminName,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      deviceId: deviceId ?? this.deviceId,
      stationId: stationId ?? this.stationId,
      tenantId: tenantId ?? this.tenantId,
      tokenType: tokenType ?? this.tokenType,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      posMode: posMode ?? this.posMode,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
    );
  }
}
