import '../../models/item_model.dart';

class MenuRemoteDataSource {
  Future<List<ItemModel>> fetchMenu() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [
      ItemModel(
        id: 1,
        name: 'Espresso',
        price: 2.5,
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
