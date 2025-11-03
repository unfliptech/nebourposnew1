import '../../data/models/meta_model.dart';

abstract class ThemeRepository {
  Future<MetaModel> pull();

  Future<void> save(MetaModel meta);
}
