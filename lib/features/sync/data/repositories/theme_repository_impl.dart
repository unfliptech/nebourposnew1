import '../../domain/repositories/theme_repository.dart';
import '../datasources/local/theme_local_ds.dart';
import '../datasources/remote/theme_remote_ds.dart';
import '../models/meta_model.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  ThemeRepositoryImpl(this._remote, this._local);

  final ThemeRemoteDataSource _remote;
  final ThemeLocalDataSource _local;

  @override
  Future<MetaModel> pull() async {
    final meta = await _remote.fetchMeta();
    await _local.save(meta);
    return meta;
  }

  @override
  Future<void> save(MetaModel meta) {
    return _local.save(meta);
  }
}
