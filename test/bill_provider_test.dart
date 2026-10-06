import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/models/customer_model.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/providers/bill_provider.dart';
import 'package:vahaal_kids_fashion/repositories/bill_repository.dart';

class MockBillRepository implements BillRepository {
  bool shouldFail = false;
  String failMessage = 'Stock error';
  Bill? lastCreatedBill;

  @override
  Future<Bill> createBillAtomic({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    if (shouldFail) {
      throw Exception(failMessage);
    }
    final created = bill.copyWith(
      id: 'mock-bill-id-123',
      billNumber: 'VKF-2026-001001',
      items: items,
      createdAt: DateTime.now(),
    );
    lastCreatedBill = created;
    return created;
  }

  @override
  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
    int limit = 50,
  }) async {
    return lastCreatedBill != null ? [lastCreatedBill!] : [];
  }

  @override
  Future<Bill> getBillById(String id) async {
    if (lastCreatedBill != null) return lastCreatedBill!;
    throw Exception('Bill not found');
  }

  @override
  Future<String> generateNextBillNumber() async {
    return 'VKF-2026-001001';
  }
}

void main() {
  group('BillProvider POS Business Logic Tests', () {
    late MockBillRepository mockRepo;
    late BillProvider provider;

    const testProduct = Product(
      id: 'prod-1',
      sku: 'VKF-TSH-001',
      productName: 'Kids Cartoon T-Shirt',
      category: 'T-Shirts',
      gender: 'Boy',
      purchasePrice: 200.0,
      sellingPrice: 400.0,
      variants: [
        ProductVariant(
          id: 'var-1',
          productId: 'prod-1',
          size: '3Y',
          color: 'Red',
          sku: 'VKF-TSH-001-3Y-RED',
          barcode: '8901234567890',
          stockQuantity: 5,
        ),
        ProductVariant(
          id: 'var-2',
          productId: 'prod-1',
          size: '4Y',
          color: 'Blue',
          sku: 'VKF-TSH-001-4Y-BLU',
          barcode: '8901234567891',
          stockQuantity: 0, // Out of stock
        ),
      ],
    );

    setUp(() {
      mockRepo = MockBillRepository();
      provider = BillProvider(repository: mockRepo);
    });

    test('Initial state of BillProvider is empty', () {
      expect(provider.cartItems.isEmpty, true);
      expect(provider.totalUniqueItems, 0);
      expect(provider.totalQuantity, 0);
      expect(provider.subtotal, 0.0);
      expect(provider.effectiveDiscount, 0.0);
      expect(provider.grandTotal, 0.0);
      expect(provider.selectedCustomer, null);
      expect(provider.paymentMethod, 'cash');
    });

    test('Adding item to cart calculates subtotal and grand total properly', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2);

      expect(provider.cartItems.length, 1);
      expect(provider.totalUniqueItems, 1);
      expect(provider.totalQuantity, 2);
      expect(provider.subtotal, 800.0);
      expect(provider.grandTotal, 800.0);
      expect(provider.canCheckout, true);
    });

    test('Prevent adding more quantity than available stock', () {
      final variant = testProduct.variants[0]; // Stock is 5
      provider.addItem(product: testProduct, variant: variant, quantity: 6);

      expect(provider.cartItems.isEmpty, true);
      expect(provider.errorMessage != null, true);
      expect(provider.errorMessage!.contains('Insufficient stock'), true);
    });

    test('Quantity increment, decrement and removal', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 1);

      // Increment
      provider.incrementQuantity(variant.id!);
      expect(provider.totalQuantity, 2);
      expect(provider.subtotal, 800.0);

      // Decrement
      provider.decrementQuantity(variant.id!);
      expect(provider.totalQuantity, 1);
      expect(provider.subtotal, 400.0);

      // Remove item
      provider.removeItem(variant.id!);
      expect(provider.cartItems.isEmpty, true);
      expect(provider.subtotal, 0.0);
    });

    test('Selecting customer automatically loads customer last discount', () {
      const customer = Customer(
        id: 'cust-10',
        name: 'Rahul Sharma',
        mobile: '9876543210',
        lastDiscount: 50.0,
        totalPurchase: 2500.0,
      );

      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      provider.setCustomer(customer);

      expect(provider.selectedCustomer?.name, 'Rahul Sharma');
      expect(provider.discountAmount, 50.0);
      expect(provider.effectiveDiscount, 50.0);
      expect(provider.grandTotal, 750.0); // 800 - 50 = 750
    });

    test('Modifying discount calculates grand total correctly', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      provider.setDiscountAmount(100.0);
      expect(provider.effectiveDiscount, 100.0);
      expect(provider.grandTotal, 700.0);

      // Discount cannot exceed subtotal
      provider.setDiscountAmount(9999.0);
      expect(provider.effectiveDiscount, 800.0);
      expect(provider.grandTotal, 0.0);
    });

    test('Payment method selection', () {
      provider.setPaymentMethod('upi');
      expect(provider.paymentMethod, 'upi');

      provider.setPaymentMethod('card');
      expect(provider.paymentMethod, 'card');
    });

    test('Atomic checkout completes successfully and clears cart', () async {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2);
      provider.setPaymentMethod('upi');

      const customer = Customer(
        id: 'cust-1',
        name: 'Sita Ram',
        mobile: '9988776655',
        lastDiscount: 0.0,
      );
      provider.setCustomer(customer);

      final createdBill = await provider.checkout(cashierId: 'cashier-1');

      expect(createdBill, isNotNull);
      expect(createdBill!.billNumber, 'VKF-2026-001001');
      expect(createdBill.items.length, 1);
      expect(createdBill.grandTotal, 800.0);
      expect(createdBill.paymentMethod, 'upi');

      // Cart should be cleared after checkout
      expect(provider.cartItems.isEmpty, true);
      expect(provider.selectedCustomer, null);
      expect(provider.discountAmount, 0.0);
      expect(provider.lastCompletedBill, isNotNull);
    });

    test('Checkout failure sets error message and preserves cart', () async {
      mockRepo.shouldFail = true;
      mockRepo.failMessage = 'Insufficient stock for SKU: VKF-TSH-001-3Y-RED';

      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2);

      final createdBill = await provider.checkout(cashierId: 'cashier-1');

      expect(createdBill, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage!.contains('Insufficient stock'), true);
      // Cart items are preserved so cashier can adjust
      expect(provider.cartItems.length, 1);
    });
  });
}
