import '../../models/meta_model.dart';

class ThemeLocalDataSource {
  MetaModel? _cache;

  Future<void> save(MetaModel meta) async {
    _cache = meta;
  }

  MetaModel? read() => _cache;
}
