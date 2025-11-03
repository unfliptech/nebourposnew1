import 'package:flutter/material.dart';

class FoodOrderView extends StatelessWidget {
  const FoodOrderView({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        '${label.toUpperCase()} BILLING',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
