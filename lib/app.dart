import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/widgets/custom_title_bar.dart';
import 'shared/widgets/custom_footer_bar.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);
    final themeMode = ref.watch(themeModeProvider).maybeWhen(
          data: (mode) => mode,
          orElse: () => ThemeMode.system,
        );

    return MaterialApp.router(
      title: 'Nebour POS',
      debugShowCheckedModeBanner: false,
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // 🔧 Inject titlebar + footer globally
        return Scaffold(
          body: Column(
            children: [
              const CustomTitleBar(),
              Expanded(child: child ?? const SizedBox()),
              const CustomFooterBar(),
            ],
          ),
        );
      },
    );
  }
}
