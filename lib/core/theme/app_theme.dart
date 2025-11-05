import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional JSON config for themes (can be null). Replace later with a repo.
final themeConfigProvider = StateProvider<Map<String, dynamic>?>((_) => null);

/// Controls ThemeMode globally. You can wire a settings page to change this.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);

/// Exposes ThemeData for light/dark, built from optional themeConfig JSON.
final appThemeProvider = Provider<AppThemeData>((ref) {
  final cfg = ref.watch(themeConfigProvider);
  return AppThemeData(themeConfig: cfg);
});

class AppThemeData {
  const AppThemeData({this.themeConfig});
  final Map<String, dynamic>? themeConfig;

  ThemeData get light {
    final p = _resolve(themeConfig?['light'], _Palette.lightDefaults());
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: p.primary,
      secondary: p.accent,
      surface: p.surface,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      dividerColor: scheme.outlineVariant,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.text,
        displayColor: p.text,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: p.background,
        foregroundColor: p.text,
      ),
      cardColor: p.surface,
    );
  }

  ThemeData get dark {
    final p = _resolve(themeConfig?['dark'], _Palette.darkDefaults());
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: p.primary,
      secondary: p.accent,
      surface: p.surface,
    );

    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      dividerColor: scheme.outlineVariant,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: p.text,
        displayColor: p.text,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: p.background,
        foregroundColor: p.text,
      ),
      cardColor: p.surface,
    );
  }

  _Palette _resolve(dynamic data, _Palette defaults) {
    if (data is! Map) return defaults;
    Color parse(dynamic v, Color fb) {
      if (v is String && v.isNotEmpty) {
        final n = v.startsWith('#') ? v.substring(1) : v;
        final hex = (n.length == 6) ? 'FF$n' : (n.length == 8 ? n : null);
        final val = hex == null ? null : int.tryParse(hex, radix: 16);
        if (val != null) return Color(val);
      }
      return fb;
    }

    return _Palette(
      primary: parse(data['primary'], defaults.primary),
      accent: parse(data['accent'], defaults.accent),
      background: parse(data['background'], defaults.background),
      surface: parse(data['surface'], defaults.surface),
      text: parse(data['text'], defaults.text),
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

  static _Palette lightDefaults() => const _Palette(
        primary: Color(0xFFE53935),
        accent: Color(0xFF3F8CFF),
        background: Color(0xFFF6F7F9),
        surface: Colors.white,
        text: Colors.black87,
      );

  static _Palette darkDefaults() => const _Palette(
        primary: Color(0xFFE53935),
        accent: Color(0xFF3F8CFF),
        background: Color(0xFF121212),
        surface: Color(0xFF1E1E1E),
        text: Colors.white,
      );
}
