import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/menu_local_ds.dart';
import '../../data/datasources/local/theme_local_ds.dart';
import '../../data/datasources/remote/menu_remote_ds.dart';
import '../../data/datasources/remote/theme_remote_ds.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../data/repositories/theme_repository_impl.dart';
import '../../domain/entities/sync_flags.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../domain/repositories/theme_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl(MenuRemoteDataSource(), MenuLocalDataSource());
});

final themeSyncRepositoryProvider = Provider<ThemeRepository>((ref) {
  return ThemeRepositoryImpl(ThemeRemoteDataSource(), ThemeLocalDataSource());
});

final syncEngineProvider = AsyncNotifierProvider<SyncEngine, SyncFlags>(
  SyncEngine.new,
);

class SyncEngine extends AsyncNotifier<SyncFlags> {
  @override
  FutureOr<SyncFlags> build() {
    return const SyncFlags(menuOutdated: true, themeOutdated: true);
  }

  Future<void> syncMenu() async {
    final repository = ref.read(menuRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final items = await repository.pull();
      return _markSynced(menuSynced: items.isNotEmpty);
    });
  }

  Future<void> syncTheme() async {
    final repository = ref.read(themeSyncRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.pull();
      return _markSynced(themeSynced: true);
    });
  }

  SyncFlags _markSynced({bool? menuSynced, bool? themeSynced}) {
    final current =
        state.value ?? const SyncFlags(menuOutdated: true, themeOutdated: true);
    return SyncFlags(
      menuOutdated: menuSynced == true ? false : current.menuOutdated,
      themeOutdated: themeSynced == true ? false : current.themeOutdated,
    );
  }
}
