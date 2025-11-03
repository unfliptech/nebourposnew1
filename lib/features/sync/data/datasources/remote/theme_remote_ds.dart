import '../../models/meta_model.dart';

class ThemeRemoteDataSource {
  Future<MetaModel> fetchMeta() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MetaModel(
      themeHash: 'hash-theme',
      menuHash: 'hash-menu',
      updatedAt: DateTime.now(),
    );
  }
}
