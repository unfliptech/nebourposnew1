import '../../../../../core/data/isar_service.dart';
import '../../models/sync_snapshot.dart';

class MetaLocalDataSource {
  MetaLocalDataSource(this._isarService);

  final IsarService _isarService;

  SyncSnapshot? readSnapshot() {
    return _isarService.isar.syncSnapshots.getSync(SyncSnapshot.primaryId);
  }

  bool get dataImported => (readSnapshot()?.hasData ?? false);

  DateTime? get lastSyncAt => readSnapshot()?.syncedAt?.toLocal();

  bool get requiresPasscode {
    final snapshot = readSnapshot();
    if (snapshot == null) {
      return false;
    }
    for (final feature in snapshot.features) {
      final key = (feature.key ?? '').toUpperCase();
      if (key == 'REQUIRE_PASSCODE') {
        return feature.enabled ?? false;
      }
    }
    return false;
  }

  Map<String, String?> get adminProfile {
    final snapshot = readSnapshot();
    if (snapshot == null) {
      return const {'id': null, 'name': null, 'role': null};
    }
    final admin = snapshot.admins.isNotEmpty ? snapshot.admins.first : null;
    return {
      'id': admin?.id,
      'name': admin?.name,
      'role': admin?.role,
    };
  }

  Future<void> saveSnapshot(SyncSnapshot snapshot) async {
    final isar = _isarService.isar;
    final existing = isar.syncSnapshots.getSync(SyncSnapshot.primaryId);
    final now = DateTime.now().toUtc();
    snapshot
      ..id = SyncSnapshot.primaryId
      ..createdAt = existing?.createdAt ?? now
      ..updatedAt = now;
    await isar.writeTxn(() async {
      await isar.syncSnapshots.put(snapshot);
    });
  }

  Future<void> clear() async {
    final isar = _isarService.isar;
    await isar.writeTxn(() async {
      await isar.syncSnapshots.delete(SyncSnapshot.primaryId);
    });
  }

  Stream<SyncSnapshot?> watchSnapshot({bool fireImmediately = true}) {
    return _isarService.isar.syncSnapshots
        .watchObject(SyncSnapshot.primaryId, fireImmediately: fireImmediately);
  }
}
