import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../providers/billing_controller.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(billingControllerProvider);

    return AppScaffold(
      appBar: AppBar(title: const Text('Billing')),
      body: state.when(
        data: (orders) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(
              title: Text('Order ${order.id}'),
              subtitle: Text('Total: ${order.total}'),
            );
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: orders.length,
        ),
        error: (error, stackTrace) => Center(
          child: Text('Failed to load orders: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            ref.read(billingControllerProvider.notifier).createSampleOrder(),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}
