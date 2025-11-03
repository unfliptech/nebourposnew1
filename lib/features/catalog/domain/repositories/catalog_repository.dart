import '../entities/item.dart';

abstract class CatalogRepository {
  Future<List<CatalogItem>> fetchItems();
}
