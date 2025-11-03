import '../../domain/entities/order.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/local/billing_local_ds.dart';
import '../datasources/remote/billing_remote_ds.dart';
import '../models/order_model.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._remote, this._local);

  final BillingRemoteDataSource _remote;
  final BillingLocalDataSource _local;

  @override
  Future<List<Order>> fetchOrders() async {
    final remoteOrders = await _remote.fetchOrders();
    final localOrders = await _local.all();
    return [...remoteOrders, ...localOrders];
  }

  @override
  Future<void> saveOrder(Order order) async {
    final model = OrderModel(
      id: order.id,
      lines: order.lines,
      createdAt: order.createdAt,
    );
    await _local.saveOrder(model);
  }
}
