import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/local/meta_local_ds.dart';
import '../../domain/mappers/sync_snapshot_mapper.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../data/models/sync_snapshot.dart';

final metaLocalDataSourceProvider = Provider<MetaLocalDataSource>((ref) {
  final isar = ref.watch(isarServiceProvider);
  return MetaLocalDataSource(isar);
});

final dineInSnapshotProvider = StreamProvider<SyncDineIn?>((ref) {
  final meta = ref.watch(metaLocalDataSourceProvider);
  return meta.watchSnapshot().map(
        (snapshot) => snapshot?.toDomainResult().dineIn,
      );
});

final syncSnapshotStreamProvider = StreamProvider<SyncSnapshot?>((ref) {
  final meta = ref.watch(metaLocalDataSourceProvider);
  return meta.watchSnapshot();
});
