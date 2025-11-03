import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/session.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../sync/data/models/sync_snapshot.dart';
import '../../../sync/domain/mappers/sync_snapshot_mapper.dart';
import '../../../sync/domain/repositories/sync_repository.dart';
import '../../../sync/presentation/providers/meta_provider.dart';
import '../../../sync/application/sync_service.dart';

class HomeState {
  const HomeState({
    required this.session,
    required this.snapshot,
    required this.syncResult,
  });

  final Session session;
  final SyncSnapshot? snapshot;
  final SyncResult? syncResult;

  DateTime? get lastSyncedAt {
    final domainSync = syncResult?.syncedAt;
    if (domainSync != null) return domainSync.toLocal();
    return snapshot?.syncedAt?.toLocal();
  }
}

final homeProvider =
    AutoDisposeAsyncNotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends AutoDisposeAsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final repository = ref.watch(authRepositoryProvider);
    final session = await repository.restoreSession();
    if (session == null) {
      throw const HomeSessionMissingException();
    }

    final meta = ref.watch(metaLocalDataSourceProvider);
    final snapshot = meta.readSnapshot();
    var syncResult = snapshot?.toDomainResult();

    // 🪵 DEBUG: Print snapshot details to console
    if (snapshot != null) {
      developer
          .log('------------------- ISAR SNAPSHOT DEBUG -------------------');
      developer.log('Status: ${snapshot.status}');
      developer.log('Synced At: ${snapshot.syncedAt}');
      developer
          .log('Tenant: ${snapshot.tenant?.name} (${snapshot.tenant?.id})');
      developer
          .log('Branch: ${snapshot.branch?.name} (${snapshot.branch?.id})');
      developer.log('Features: ${snapshot.features.length}');
      for (final feature in snapshot.features) {
        developer.log(
          '  - ${feature.key} -> enabled=${feature.enabled} meta=${feature.featureMetaJson}',
        );
      }
      developer.log('Admins: ${snapshot.admins.length}');
      for (final admin in snapshot.admins) {
        developer.log(
          '  - ${admin.name} -> passcode=${admin.passcode} active=${admin.isActive}',
        );
      }
      final menu = snapshot.menu;
      if (menu != null) {
        final totalCategories = menu.categories.length;
        final totalSubcategories = menu.categories
            .map((category) => category.subcategories.length)
            .fold<int>(0, (acc, value) => acc + value);
        final totalItems = menu.categories
            .expand((category) => category.subcategories)
            .expand((subcategory) => subcategory.items)
            .length;
        developer.log(
          'Menu categories=$totalCategories subcategories=$totalSubcategories items=$totalItems',
        );
      }
      developer
          .log('----------------------------------------------------------');
    } else {
      developer.log('No snapshot found in Isar database.');
    }
    // Fallback if no mapped features
    if (syncResult == null || syncResult.features.isEmpty) {
      final lastOutcome = ref.read(lastSyncOutcomeProvider);
      if (lastOutcome?.result != null) {
        syncResult = lastOutcome!.result!;
      }
    }

    return HomeState(
      session: session,
      snapshot: snapshot,
      syncResult: syncResult,
    );
  }
}

class HomeSessionMissingException implements Exception {
  const HomeSessionMissingException();
}
