import 'package:flutter/material.dart';

import '../../config/theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Clear cart
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add items to get started',
              style: TextStyle(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
