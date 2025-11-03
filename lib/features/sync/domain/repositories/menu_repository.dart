import '../../data/models/item_model.dart';

abstract class MenuRepository {
  Future<List<ItemModel>> pull();

  Future<void> push(List<ItemModel> items);
}
