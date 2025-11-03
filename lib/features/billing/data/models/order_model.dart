import '../../domain/entities/order.dart';
import '../../domain/value_objects/money.dart';

class OrderModel extends Order {
  OrderModel({
    required super.id,
    required super.lines,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List<dynamic>).map((line) {
      final map = line as Map<String, dynamic>;
      return OrderLine(
        itemId: map['item_id'] as int,
        quantity: map['qty'] as int,
        price: Money((map['price'] as num).toDouble()),
      );
    }).toList();

    return OrderModel(
      id: json['id'] as String,
      lines: lines,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lines': lines
          .map((line) => {
                'item_id': line.itemId,
                'qty': line.quantity,
                'price': line.price.amount,
              })
          .toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
