import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl();
});

final catalogProvider = FutureProvider<List<CatalogItem>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.fetchItems();
});
