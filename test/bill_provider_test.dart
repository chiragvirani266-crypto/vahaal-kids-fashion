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
  group('BillProvider POS & Discount Memory Tests', () {
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
      expect(provider.discountValue, 0.0);
      expect(provider.discountType, DiscountType.fixed);
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

    test('Customer discount memory: Loads customer.last_discount on selection', () {
      const customer = Customer(
        id: 'cust-10',
        name: 'Priya Sharma',
        mobile: '9876543210',
        lastDiscount: 60.0, // Previous discount was ₹60
        totalPurchase: 3200.0,
      );

      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      // Select customer
      provider.setCustomer(customer);

      expect(provider.selectedCustomer?.name, 'Priya Sharma');
      expect(provider.discountType, DiscountType.fixed);
      expect(provider.discountValue, 60.0);
      expect(provider.effectiveDiscount, 60.0);
      expect(provider.grandTotal, 740.0); // 800 - 60 = 740
    });

    test('Cashier can modify loaded customer discount to another fixed amount', () {
      const customer = Customer(
        id: 'cust-10',
        name: 'Priya Sharma',
        mobile: '9876543210',
        lastDiscount: 60.0,
      );

      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800
      provider.setCustomer(customer);

      // Cashier changes discount to ₹120
      provider.setDiscountValue(120.0);

      expect(provider.discountValue, 120.0);
      expect(provider.effectiveDiscount, 120.0);
      expect(provider.grandTotal, 680.0); // 800 - 120 = 680
    });

    test('Support percentage discount calculation', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      // Switch to percentage discount
      provider.setDiscountType(DiscountType.percentage);
      provider.setDiscountValue(15.0); // 15%

      expect(provider.discountType, DiscountType.percentage);
      expect(provider.discountValue, 15.0);
      // 15% of 800 = 120
      expect(provider.effectiveDiscount, 120.0);
      expect(provider.grandTotal, 680.0); // 800 - 120 = 680
    });

    test('Validate discount cannot exceed bill subtotal (Fixed amount capping)', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      provider.setDiscountType(DiscountType.fixed);
      provider.setDiscountValue(1500.0); // Attempt to apply ₹1500 discount on ₹800 subtotal

      expect(provider.isDiscountExceedingSubtotal, true);
      // Effective discount must be strictly capped at subtotal
      expect(provider.effectiveDiscount, 800.0);
      expect(provider.grandTotal, 0.0);
    });

    test('Validate percentage discount cannot exceed 100% / subtotal', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      provider.setDiscountType(DiscountType.percentage);
      provider.setDiscountValue(120.0); // 120%

      expect(provider.isDiscountExceedingSubtotal, true);
      // Effective discount must be capped at subtotal
      expect(provider.effectiveDiscount, 800.0);
      expect(provider.grandTotal, 0.0);
    });

    test('Bill permanently preserves its own discount after atomic checkout', () async {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800
      provider.setPaymentMethod('upi');

      const customer = Customer(
        id: 'cust-1',
        name: 'Aarav Mehta',
        mobile: '9988776655',
        lastDiscount: 20.0,
      );
      provider.setCustomer(customer);

      // Cashier switches to 10% discount (= ₹80)
      provider.setDiscountType(DiscountType.percentage);
      provider.setDiscountValue(10.0);

      final createdBill = await provider.checkout(cashierId: 'cashier-1');

      expect(createdBill, isNotNull);
      expect(createdBill!.subtotal, 800.0);
      expect(createdBill.discount, 80.0); // Preserved permanently as ₹80 numeric value on the bill
      expect(createdBill.grandTotal, 720.0);
      expect(createdBill.paymentMethod, 'upi');

      // Cart reset
      expect(provider.cartItems.isEmpty, true);
      expect(provider.selectedCustomer, null);
      expect(provider.discountValue, 0.0);
    });
  });
}
