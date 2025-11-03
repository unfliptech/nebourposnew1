import '../../domain/entities/item.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  @override
  Future<List<CatalogItem>> fetchItems() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      CatalogItem(id: 1, name: 'Espresso', price: 2.5),
      CatalogItem(id: 2, name: 'Cappuccino', price: 3.0),
    ];
  }
}
