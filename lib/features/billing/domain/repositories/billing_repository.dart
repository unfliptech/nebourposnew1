import '../entities/order.dart';

abstract class BillingRepository {
  Future<List<Order>> fetchOrders();

  Future<void> saveOrder(Order order);
}
