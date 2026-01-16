import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_tutorial/controllers/cart_controller.dart';

void main() {
  test('CartItem.toOrderItem sends int product_id when numeric', () {
    final item = CartItem(
      productId: '123',
      productName: 'Test',
      price: 10,
      sellerId: '7',
      sellerName: 'Seller',
      quantity: 2,
    );

    final json = item.toOrderItem();
    expect(json['product_id'], 123);
    expect(json['quantity'], 2);
    expect(json['price'], 10);
  });

  test('CartItem.toOrderItem keeps product_id as string when non-numeric', () {
    final item = CartItem(
      productId: 'abc-123',
      productName: 'Test',
      price: 10,
      sellerId: '7',
      sellerName: 'Seller',
      quantity: 1,
    );

    final json = item.toOrderItem();
    expect(json['product_id'], 'abc-123');
  });
}

