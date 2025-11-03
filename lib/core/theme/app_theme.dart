import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebourpos2/core/providers/core_providers.dart';

import 'app_colors.dart';

final themeConfigProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final repository = ref.watch(themeRepositoryProvider);
  return repository.loadThemeConfig();
});

final appThemeProvider = Provider<AppThemeData>((ref) {
  final themeConfig = ref.watch(themeConfigProvider).maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );
  return AppThemeData(themeConfig: themeConfig);
});

final themeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final repository = ref.watch(themeRepositoryProvider);
  return repository.loadThemeMode();
});

class AppThemeData {
  const AppThemeData({this.themeConfig});

  final Map<String, dynamic>? themeConfig;

  ThemeData get light {
    final palette = _resolvePalette(
      themeConfig?['light'],
      defaults: _Palette(
        primary: AppColors.primary,
        accent: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.surface,
        text: Colors.black87,
      ),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: palette.primary,
      secondary: palette.accent,
      surface: palette.surface,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: palette.background,
        foregroundColor: palette.text,
      ),
      cardColor: palette.surface,
    );
  }

  ThemeData get dark {
    final palette = _resolvePalette(
      themeConfig?['dark'],
      defaults: _Palette(
        primary: AppColors.primaryDark,
        accent: AppColors.secondary,
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
        text: Colors.white,
      ),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: palette.primary,
      secondary: palette.accent,
      surface: palette.surface,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: palette.text,
        displayColor: palette.text,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: palette.background,
        foregroundColor: palette.text,
      ),
      cardColor: palette.surface,
    );
  }

  _Palette _resolvePalette(
    dynamic data, {
    required _Palette defaults,
  }) {
    if (data is! Map) {
      return defaults;
    }
    Color parseColor(dynamic value, Color fallback) {
      if (value is String && value.isNotEmpty) {
        final normalized = value.startsWith('#') ? value.substring(1) : value;
        final buffer = StringBuffer();
        if (normalized.length == 6) {
          buffer.write('FF$normalized');
        } else if (normalized.length == 8) {
          buffer.write(normalized);
        } else {
          return fallback;
        }
        final parsed = int.tryParse(buffer.toString(), radix: 16);
        if (parsed != null) {
          return Color(parsed);
        }
      }
      return fallback;
    }

    return _Palette(
      primary: parseColor(data['primary'], defaults.primary),
      accent: parseColor(data['accent'], defaults.accent),
      background: parseColor(data['background'], defaults.background),
      surface: parseColor(data['surface'], defaults.surface),
      text: parseColor(data['text'], defaults.text),
    );
  }
}

class _Palette {
  const _Palette({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
  });

  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color text;
}
