import '../../models/order_model.dart';

class BillingLocalDataSource {
  final List<OrderModel> _orders = [];

  Future<void> saveOrder(OrderModel order) async {
    _orders.add(order);
  }

  Future<List<OrderModel>> all() async {
    return List.unmodifiable(_orders);
  }
}
