import '../../models/order_model.dart';

class BillingRemoteDataSource {
  Future<List<OrderModel>> fetchOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const [];
  }
}
