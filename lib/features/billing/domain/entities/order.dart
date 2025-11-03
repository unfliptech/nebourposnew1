import '../value_objects/money.dart';

class OrderLine {
  const OrderLine({
    required this.itemId,
    required this.quantity,
    required this.price,
  });

  final int itemId;
  final int quantity;
  final Money price;

  Money get total => Money(price.amount * quantity);
}

class Order {
  const Order({
    required this.id,
    required this.lines,
    required this.createdAt,
  });

  final String id;
  final List<OrderLine> lines;
  final DateTime createdAt;

  Money get total => lines.fold(const Money(0),
      (previousValue, element) => previousValue + element.total);
}
