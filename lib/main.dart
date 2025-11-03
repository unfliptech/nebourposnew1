// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:untitled1test/shared/widgets/custom_footer_bar.dart';
// import 'package:untitled1test/shared/widgets/custom_title_bar.dart';
// import 'package:window_manager/window_manager.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await _configureWindow();

//   runApp(const MyApp());
// }

// /// Detect if running on desktop
// bool get _isDesktop =>
//     !kIsWeb &&
//     (defaultTargetPlatform == TargetPlatform.windows ||
//         defaultTargetPlatform == TargetPlatform.macOS ||
//         defaultTargetPlatform == TargetPlatform.linux);

// /// Configure and show custom window
// Future<void> _configureWindow() async {
//   if (!_isDesktop) return;

//   await windowManager.ensureInitialized();

//   const options = WindowOptions(
//     size: Size(1280, 800),
//     minimumSize: Size(900, 600),
//     center: true,
//     titleBarStyle: TitleBarStyle.hidden, // 🚫 hide system title bar
//     backgroundColor: Colors.white,
//   );

//   await windowManager.waitUntilReadyToShow(options, () async {
//     await windowManager.show();
//     await windowManager.focus();
//   });
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Nebour POS 1',
//       debugShowCheckedModeBanner: false,
//       themeMode: ThemeMode.system,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
//       ),
//       darkTheme: ThemeData.dark(useMaterial3: true),
//       home: const MainScreen(),
//     );
//   }
// }

// /// Example screen with custom title bar + content
// class MainScreen extends StatelessWidget {
//   const MainScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           const CustomTitleBar(), // 🧱 custom title bar
//           Expanded(
//             child: Center(
//               child: Text(
//                 'Welcome to Nebour Wajahath',
//                 style: Theme.of(context).textTheme.headlineMedium,
//               ),
//             ),
//           ),
//           CustomFooterBar(),
//         ],
//       ),
//     );
//   }
// }

import 'bootstrap.dart';

/// Entry point for Nebour POS
Future<void> main() async {
  // Ensure Flutter engine is fully initialized
  await bootstrap();
}
