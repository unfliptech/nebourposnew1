import 'package:flutter/material.dart';

import 'custom_title_bar.dart';
import 'app_header_bar.dart';
import 'custom_footer_bar.dart';

/// Single global Scaffold. All pages render inside [body].
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomTitleBar(), // window chrome
          const AppHeaderBar(), // in-app header with logo + title
          Expanded(child: body), // content
          const CustomFooterBar(),
        ],
      ),
    );
  }
}
