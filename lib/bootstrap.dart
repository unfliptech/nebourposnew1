import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/data/isar_service.dart';
import 'core/providers/core_providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize desktop window (hide titlebar early) ---
  await _configureWindow();

  // --- Initialize local database ---
  await IsarService.init();

  // --- Prepare Riverpod overrides ---
  final overrides = await createCoreOverrides();

  // --- Launch Nebour POS app ---
  runApp(
    ProviderScope(
      overrides: overrides,
      observers: const [LoggerProviderObserver()],
      child: const App(),
    ),
  );
}

/// Detect if app is running on a desktop platform (non-web)
bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Configure window behavior for desktop builds
Future<void> _configureWindow() async {
  if (!_isDesktop) return;

  await windowManager.ensureInitialized();

  const minSize = Size(1024, 720);
  const initialSize = Size(1280, 800);

  // --- Apply hidden style immediately before the window even shows ---
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  const options = WindowOptions(
    size: initialSize,
    minimumSize: minSize,
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
  );

  // --- Create the window without drawing the system bar ---
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setMinimumSize(minSize);
    await windowManager.show();
    await windowManager.focus();

    // re-apply to override any OS re-draw
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
  });

  await _waitForValidWindowMetrics();
}

/// Wait until the window has valid non-zero metrics
Future<void> _waitForValidWindowMetrics() async {
  if (!_isDesktop) return;

  Size size = await windowManager.getSize();
  int retries = 0;

  // Wait up to ~3 seconds total
  while ((size.width < 100 || size.height < 100) && retries < 60) {
    await Future.delayed(const Duration(milliseconds: 50));
    size = await windowManager.getSize();
    retries++;
  }

  // Small delay to stabilize UI frame
  await Future.delayed(const Duration(milliseconds: 100));
}
