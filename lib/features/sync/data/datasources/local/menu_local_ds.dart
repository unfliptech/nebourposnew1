import '../../models/item_model.dart';

class MenuLocalDataSource {
  final List<ItemModel> _cache = [];

  Future<void> saveMenu(List<ItemModel> items) async {
    _cache
      ..clear()
      ..addAll(items);
  }

  List<ItemModel> readMenu() => List.unmodifiable(_cache);
}
