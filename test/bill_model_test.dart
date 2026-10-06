import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';

void main() {
  group('Bill and BillItem Models Unit Tests', () {
    test('BillItem calculations and copyWith', () {
      const item = BillItem(
        variantId: 'v123',
        productNameSnapshot: 'Cotton Graphic T-Shirt',
        skuSnapshot: 'VKF-TSH-001',
        sizeSnapshot: '4Y',
        colorSnapshot: 'Navy Blue',
        quantity: 2,
        unitPrice: 499.0,
        discount: 50.0,
        total: 948.0,
        availableStock: 10,
      );

      expect(item.variantDescription, '4Y / Navy Blue');
      expect(item.quantity, 2);
      expect(item.unitPrice, 499.0);
      expect(item.availableStock, 10);

      final updated = item.copyWith(quantity: 3, total: 1447.0);
      expect(updated.quantity, 3);
      expect(updated.total, 1447.0);
      expect(updated.variantDescription, '4Y / Navy Blue');
    });

    test('BillItem toRpcJson matches PostgreSQL RPC format', () {
      const item = BillItem(
        productId: 'p1',
        variantId: 'v1',
        productNameSnapshot: 'Denim Dungarees',
        skuSnapshot: 'VKF-DNG-01',
        sizeSnapshot: '2Y',
        colorSnapshot: 'Blue',
        quantity: 1,
        unitPrice: 899.0,
        discount: 0.0,
        total: 899.0,
      );

      final rpcJson = item.toRpcJson();
      expect(rpcJson['product_id'], 'p1');
      expect(rpcJson['variant_id'], 'v1');
      expect(rpcJson['product_name_snapshot'], 'Denim Dungarees');
      expect(rpcJson['sku_snapshot'], 'VKF-DNG-01');
      expect(rpcJson['size_snapshot'], '2Y');
      expect(rpcJson['color_snapshot'], 'Blue');
      expect(rpcJson['quantity'], 1);
      expect(rpcJson['unit_price'], 899.0);
      expect(rpcJson['discount'], 0.0);
      expect(rpcJson['total'], 899.0);
    });

    test('Bill serialization and totals', () {
      final billDate = DateTime(2026, 10, 6, 12, 0);
      final bill = Bill(
        id: 'bill-1',
        billNumber: 'VKF-2026-001001',
        customerId: 'cust-1',
        customerNameSnapshot: 'Aarav Patel',
        customerMobileSnapshot: '9876543210',
        billDate: billDate,
        subtotal: 1500.0,
        discount: 150.0,
        grandTotal: 1350.0,
        paymentMethod: 'upi',
        items: const [
          BillItem(
            variantId: 'v1',
            productNameSnapshot: 'Item 1',
            skuSnapshot: 'SKU1',
            sizeSnapshot: '3Y',
            colorSnapshot: 'Red',
            quantity: 2,
            unitPrice: 500.0,
            total: 1000.0,
          ),
          BillItem(
            variantId: 'v2',
            productNameSnapshot: 'Item 2',
            skuSnapshot: 'SKU2',
            sizeSnapshot: '4Y',
            colorSnapshot: 'Blue',
            quantity: 1,
            unitPrice: 500.0,
            total: 500.0,
          ),
        ],
      );

      expect(bill.totalItemsCount, 2);
      expect(bill.totalUnitsCount, 3);
      expect(bill.displayCustomerName, 'Aarav Patel');
      expect(bill.displayCustomerMobile, '9876543210');
      expect(bill.grandTotal, 1350.0);

      final rpcJson = bill.toRpcJson();
      expect(rpcJson['bill_number'], 'VKF-2026-001001');
      expect(rpcJson['customer_id'], 'cust-1');
      expect(rpcJson['subtotal'], 1500.0);
      expect(rpcJson['discount'], 150.0);
      expect(rpcJson['grand_total'], 1350.0);
      expect(rpcJson['payment_method'], 'upi');
    });
  });
}
