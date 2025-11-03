class ItemModel {
  const ItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final double price;
  final DateTime updatedAt;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
