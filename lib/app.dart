import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(appThemeProvider);
    final mode = ref.watch(themeModeProvider);

    final router = createRouter(ref);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Nebour POSs',
      theme: appTheme.light,
      darkTheme: appTheme.dark,
      themeMode: mode,
      routerConfig: router,
    );
  }
}
