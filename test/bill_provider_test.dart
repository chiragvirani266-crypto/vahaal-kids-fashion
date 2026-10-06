import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/bill_filter_model.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/models/customer_model.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/providers/bill_provider.dart';
import 'package:vahaal_kids_fashion/repositories/bill_repository.dart';
import 'package:vahaal_kids_fashion/services/receipt_service.dart';

class MockBillRepository implements BillRepository {
  bool shouldFail = false;
  String failMessage = 'Stock error';
  Bill? lastCreatedBill;
  List<Bill> mockBills = [];

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
    mockBills.insert(0, created);
    return created;
  }

  @override
  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
    int page = 0,
    int pageSize = 20,
    int limit = 50,
  }) async {
    var list = List<Bill>.from(mockBills);

    if (startDate != null) {
      list = list.where((b) => b.billDate.isAfter(startDate) || b.billDate.isAtSameMomentAs(startDate)).toList();
    }
    if (endDate != null) {
      list = list.where((b) => b.billDate.isBefore(endDate) || b.billDate.isAtSameMomentAs(endDate)).toList();
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod.toLowerCase() != 'all') {
      list = list.where((b) => b.paymentMethod.toLowerCase() == paymentMethod.toLowerCase()).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list.where((b) {
        final matchesNumber = b.billNumber.toLowerCase().contains(q);
        final matchesCust = b.customerNameSnapshot?.toLowerCase().contains(q) ?? false;
        final matchesMobile = b.customerMobileSnapshot?.contains(q) ?? false;
        return matchesNumber || matchesCust || matchesMobile;
      }).toList();
    }

    final from = page * pageSize;
    if (from >= list.length) return [];
    final to = (from + pageSize) > list.length ? list.length : (from + pageSize);
    return list.sublist(from, to);
  }

  @override
  Future<int> getBillsCount({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
  }) async {
    final list = await getBills(
      startDate: startDate,
      endDate: endDate,
      search: search,
      paymentMethod: paymentMethod,
      page: 0,
      pageSize: 1000,
    );
    return list.length;
  }

  @override
  Future<Bill> getBillById(String id) async {
    final found = mockBills.firstWhere((b) => b.id == id, orElse: () => lastCreatedBill!);
    return found;
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
    });

    test('Cannot add more quantity than available stock', () {
      final variant = testProduct.variants[0]; // 5 in stock

      provider.addItem(product: testProduct, variant: variant, quantity: 4);
      expect(provider.totalQuantity, 4);

      // Attempt to add 2 more (total 6 > 5)
      provider.addItem(product: testProduct, variant: variant, quantity: 2);
      expect(provider.totalQuantity, 4); // Should not increase
      expect(provider.errorMessage, contains('Only 5 in stock'));
    });

    test('Customer discount memory: Loads customer.last_discount on selection', () {
      const customer = Customer(
        id: 'cust-1',
        name: 'Priya Patel',
        mobile: '9876543210',
        lastDiscount: 50.0, // Last discount was ₹50
      );

      provider.setCustomer(customer);

      expect(provider.selectedCustomer?.name, 'Priya Patel');
      expect(provider.discountValue, 50.0); // Automatically populated
      expect(provider.discountType, DiscountType.fixed);
    });

    test('Support percentage discount calculation', () {
      final variant = testProduct.variants[0];
      provider.addItem(product: testProduct, variant: variant, quantity: 2); // Subtotal = 800

      provider.setDiscountType(DiscountType.percentage);
      provider.setDiscountValue(15.0); // 15% discount

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

  group('Bill Search & Server-Side Filtering Unit Tests', () {
    late MockBillRepository mockRepo;
    late BillProvider provider;

    final bill1 = Bill(
      id: 'bill-1',
      billNumber: 'VKF-2026-001001',
      customerNameSnapshot: 'Rajesh Sharma',
      customerMobileSnapshot: '9876543210',
      billDate: DateTime.now(),
      subtotal: 1000.0,
      discount: 100.0,
      grandTotal: 900.0,
      paymentMethod: 'cash',
      items: const [
        BillItem(
          productId: 'p1',
          variantId: 'v1',
          productNameSnapshot: 'Cotton Kurta',
          skuSnapshot: 'VKF-KUR-01',
          sizeSnapshot: '4Y',
          colorSnapshot: 'Yellow',
          quantity: 2,
          unitPrice: 500.0,
          discount: 0.0,
          total: 1000.0,
        ),
      ],
    );

    final bill2 = Bill(
      id: 'bill-2',
      billNumber: 'VKF-2026-001002',
      customerNameSnapshot: 'Kavita Patel',
      customerMobileSnapshot: '9123456780',
      billDate: DateTime.now().subtract(const Duration(days: 1)),
      subtotal: 2000.0,
      discount: 0.0,
      grandTotal: 2000.0,
      paymentMethod: 'upi',
      items: const [
        BillItem(
          productId: 'p2',
          variantId: 'v2',
          productNameSnapshot: 'Party Frock',
          skuSnapshot: 'VKF-FRK-02',
          sizeSnapshot: '6Y',
          colorSnapshot: 'Pink',
          quantity: 1,
          unitPrice: 2000.0,
          discount: 0.0,
          total: 2000.0,
        ),
      ],
    );

    setUp(() {
      mockRepo = MockBillRepository();
      mockRepo.mockBills = [bill1, bill2];
      provider = BillProvider(repository: mockRepo);
    });

    test('Search bill by Bill Number', () async {
      provider.setSearchQuery('001001');
      await provider.fetchBills(refresh: true);

      expect(provider.billsHistory.length, 1);
      expect(provider.billsHistory.first.billNumber, 'VKF-2026-001001');
    });

    test('Search bill by Customer Name', () async {
      provider.setSearchQuery('Kavita');
      await provider.fetchBills(refresh: true);

      expect(provider.billsHistory.length, 1);
      expect(provider.billsHistory.first.customerNameSnapshot, 'Kavita Patel');
    });

    test('Search bill by Customer Mobile', () async {
      provider.setSearchQuery('9876543210');
      await provider.fetchBills(refresh: true);

      expect(provider.billsHistory.length, 1);
      expect(provider.billsHistory.first.customerMobileSnapshot, '9876543210');
    });

    test('Filter bills by Today date filter', () async {
      provider.setDateFilter(BillDateFilterOption.today);
      await provider.fetchBills(refresh: true);

      expect(provider.billsHistory.length, 1);
      expect(provider.billsHistory.first.id, 'bill-1');
    });

    test('Filter bills by Payment Method', () async {
      provider.setPaymentFilter('upi');
      await provider.fetchBills(refresh: true);

      expect(provider.billsHistory.length, 1);
      expect(provider.billsHistory.first.paymentMethod, 'upi');
    });

    test('Reset filters returns all records', () async {
      provider.setSearchQuery('NonExistent');
      await provider.fetchBills(refresh: true);
      expect(provider.billsHistory.isEmpty, true);

      provider.resetFilters();
      await provider.fetchBills(refresh: true);
      expect(provider.billsHistory.length, 2);
    });

    test('ReceiptService formats text for WhatsApp correctly', () {
      final text = ReceiptService.formatBillText(bill1, isReprint: false);
      expect(text, contains('VAHAAL KIDS FASHION'));
      expect(text, contains('VKF-2026-001001'));
      expect(text, contains('Rajesh Sharma'));
      expect(text, contains('Cotton Kurta'));
      expect(text, contains('₹900.00'));
    });

    test('ReceiptService format includes duplicate watermark for reprint', () {
      final reprintText = ReceiptService.formatBillText(bill1, isReprint: true);
      expect(reprintText, contains('[REPRINTED DUPLICATE INVOICE]'));
    });
  });
}
