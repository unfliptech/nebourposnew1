import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/billing_local_ds.dart';
import '../../data/datasources/remote/billing_remote_ds.dart';
import '../../data/repositories/billing_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../domain/value_objects/money.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return BillingRepositoryImpl(
      BillingRemoteDataSource(), BillingLocalDataSource());
});

final billingControllerProvider =
    AsyncNotifierProvider<BillingController, List<Order>>(
  BillingController.new,
);

class BillingController extends AsyncNotifier<List<Order>> {
  @override
  FutureOr<List<Order>> build() {
    return ref.watch(billingRepositoryProvider).fetchOrders();
  }

  Future<void> createSampleOrder() async {
    final repository = ref.read(billingRepositoryProvider);
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      lines: const [
        OrderLine(itemId: 1, quantity: 1, price: Money(2.5)),
      ],
    );
    await repository.saveOrder(order);
    final current = state.value ?? const <Order>[];
    state = AsyncValue.data([...current, order]);
  }
}
