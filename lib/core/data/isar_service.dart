import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/sync/data/models/sync_snapshot.dart';

class IsarService {
  IsarService._(this._isar);

  static IsarService? _instance;

  final Isar _isar;

  static Future<void> init() async {
    if (_instance != null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        SyncSnapshotSchema,
      ],
      directory: directory.path,
      inspector: false,
    );

    _instance = IsarService._(isar);
  }

  static IsarService get instance {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'IsarService.init must be called before accessing the database.',
      );
    }
    return instance;
  }

  Isar get isar => _isar;

  Future<void> close() async {
    if (_instance == null) {
      return;
    }
    await _isar.close();
    _instance = null;
  }

  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.clear();
    });
  }
}
