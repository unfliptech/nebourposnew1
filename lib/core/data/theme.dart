import 'dart:convert';

import 'package:flutter/material.dart';

import 'secure_storage.dart';
import 'storage_keys.dart';

class ThemeRepository {
  ThemeRepository(this._storage);

  final SecureStorage _storage;

  Future<ThemeMode> loadThemeMode() async {
    final value = await _storage.read(StorageKeys.themeMode);
    return switch (value) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _storage.write(StorageKeys.themeMode, value);
  }

  Future<void> saveThemeConfig(Map<String, dynamic> config) async {
    final payload = jsonEncode(config);
    await _storage.write(StorageKeys.themeConfig, payload);
  }

  Future<Map<String, dynamic>?> loadThemeConfig() async {
    final raw = await _storage.read(StorageKeys.themeConfig);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> clearThemeConfig() {
    return _storage.delete(StorageKeys.themeConfig);
  }
}
