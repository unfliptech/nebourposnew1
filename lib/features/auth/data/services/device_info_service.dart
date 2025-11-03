import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'device_registration_payload.dart';

class DeviceInfoService {
  DeviceInfoService({
    DeviceInfoPlugin? deviceInfo,
    Future<PackageInfo> Function()? packageInfoLoader,
  })  : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final DeviceInfoPlugin _deviceInfo;
  final Future<PackageInfo> Function() _packageInfoLoader;

  Future<DeviceRegistrationPayload> buildRegistrationPayload(
    String deviceCode,
  ) async {
    final normalizedCode = deviceCode.trim().toUpperCase();
    final digitsOnlyRaw =
        normalizedCode.replaceAll(RegExp(r'[^0-9]'), '');
    final sanitizedCode = digitsOnlyRaw.length <= 12
        ? digitsOnlyRaw
        : digitsOnlyRaw.substring(0, 12);

    final info = await _safeDeviceInfo();
    final package = await _safePackageInfo();

    var platform = kIsWeb ? 'web' : Platform.operatingSystem.toLowerCase();
    var osVersion = Platform.operatingSystemVersion;
    var modelName = 'Unknown Device';
    var manufacturer = platform.isNotEmpty
        ? platform[0].toUpperCase() + platform.substring(1)
        : 'Unknown';
    var deviceName = modelName;
    var fingerprint = _buildFingerprint(platform, modelName);

    if (info is AndroidDeviceInfo) {
      platform = 'android';
      osVersion = info.version.release;
      final data = info.data;
      modelName =
          data['model']?.toString() ?? data['product']?.toString() ?? modelName;
      manufacturer = data['manufacturer']?.toString() ?? manufacturer;
      deviceName = data['device']?.toString() ?? modelName;
      fingerprint = data['fingerprint']?.toString() ??
          _buildFingerprint(platform, modelName);
    } else if (info is IosDeviceInfo) {
      platform = 'ios';
      final data = info.data;
      final systemName = data['systemName']?.toString();
      final systemVersion = data['systemVersion']?.toString();
      final pieces = <String>[
        if (systemName != null && systemName.isNotEmpty) systemName,
        if (systemVersion != null && systemVersion.isNotEmpty) systemVersion,
      ];
      if (pieces.isNotEmpty) {
        osVersion = pieces.join(' ');
      }
      if (osVersion.isEmpty) {
        osVersion = Platform.operatingSystemVersion;
      }
      modelName = data['utsname.machine']?.toString() ??
          data['model']?.toString() ??
          modelName;
      manufacturer = 'Apple';
      deviceName = data['name']?.toString() ?? modelName;
      fingerprint = data['identifierForVendor']?.toString() ??
          _buildFingerprint(platform, modelName);
    } else if (info != null) {
      final data = info.data;
      modelName =
          data['model']?.toString() ?? data['name']?.toString() ?? modelName;
      deviceName = data['device']?.toString() ??
          data['computerName']?.toString() ??
          modelName;
      fingerprint = _buildFingerprint(platform, modelName);
    }

    final appVersion = package?.version ?? '0.0.0';

    return DeviceRegistrationPayload(
      deviceCode: sanitizedCode,
      fingerprint: fingerprint,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      modelName: modelName,
      manufacturer: manufacturer,
      deviceName: deviceName,
    );
  }

  Future<BaseDeviceInfo?> _safeDeviceInfo() async {
    try {
      return await _deviceInfo.deviceInfo;
    } catch (_) {
      return null;
    }
  }

  Future<PackageInfo?> _safePackageInfo() async {
    try {
      return await _packageInfoLoader();
    } catch (_) {
      return null;
    }
  }

  String _buildFingerprint(String platform, String modelName) {
    final sanitized = modelName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    return '${platform.toUpperCase()}-$sanitized';
  }
}
