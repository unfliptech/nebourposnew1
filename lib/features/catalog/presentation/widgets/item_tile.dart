import 'package:flutter/material.dart';

import '../../domain/entities/item.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
  });

  final CatalogItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      trailing: Text('\$${item.price.toStringAsFixed(2)}'),
    );
  }
}
