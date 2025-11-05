// TODO Implement this library.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureWindow();
  runApp(const ProviderScope(child: App()));
}

Future<void> _configureWindow() async {
  if (!_isDesktop) return;

  await windowManager.ensureInitialized();

  const initialSize = Size(1200, 800);
  const minSize = Size(1024, 640);

  final opts = const WindowOptions(
    size: initialSize,
    minimumSize: minSize,
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(opts, () async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.show();
    await windowManager.focus();
  });

  // Defensive wait for stable first frame size
  var size = await windowManager.getSize();
  var retries = 0;
  while ((size.width < 100 || size.height < 100) && retries < 60) {
    await Future.delayed(const Duration(milliseconds: 50));
    size = await windowManager.getSize();
    retries++;
  }
  await Future.delayed(const Duration(milliseconds: 100));
}
