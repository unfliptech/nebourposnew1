import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dynamic page title shown in the custom title bar.
/// Default: "Nebour POS"
final pageTitleProvider = StateProvider<String>((_) => 'Nebour POSs');
