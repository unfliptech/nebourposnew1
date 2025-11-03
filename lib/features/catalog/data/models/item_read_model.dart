import '../../domain/entities/item.dart';

class ItemReadModel extends CatalogItem {
  ItemReadModel({
    required super.id,
    required super.name,
    required super.price,
  });

  factory ItemReadModel.fromJson(Map<String, dynamic> json) {
    return ItemReadModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}
