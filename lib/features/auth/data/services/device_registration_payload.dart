class DeviceRegistrationPayload {
  const DeviceRegistrationPayload({
    required this.deviceCode,
    required this.fingerprint,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
    required this.modelName,
    required this.manufacturer,
    required this.deviceName,
  });

  final String deviceCode;
  final String fingerprint;
  final String platform;
  final String osVersion;
  final String appVersion;
  final String modelName;
  final String manufacturer;
  final String deviceName;

  Map<String, dynamic> toJson() {
    return {
      'device_code': deviceCode,
      'fingerprint': fingerprint,
      'platform': platform,
      'os_version': osVersion,
      'app_version': appVersion,
      'model_name': modelName,
      'manufacturer': manufacturer,
      'device_name': deviceName,
    };
  }
}
