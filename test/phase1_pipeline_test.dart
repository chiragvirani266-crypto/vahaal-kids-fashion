import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vahaal_kids_fashion/models/analytics_model.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/models/customer_model.dart';
import 'package:vahaal_kids_fashion/models/customer_purchase_bill_model.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/models/user_profile_model.dart';
import 'package:vahaal_kids_fashion/providers/auth_provider.dart';
import 'package:vahaal_kids_fashion/providers/bill_provider.dart';
import 'package:vahaal_kids_fashion/providers/customer_provider.dart';
import 'package:vahaal_kids_fashion/providers/dashboard_provider.dart';
import 'package:vahaal_kids_fashion/providers/product_provider.dart';
import 'package:vahaal_kids_fashion/repositories/bill_repository.dart';
import 'package:vahaal_kids_fashion/repositories/customer_repository.dart';
import 'package:vahaal_kids_fashion/repositories/dashboard_repository.dart';
import 'package:vahaal_kids_fashion/repositories/product_repository.dart';
import 'package:vahaal_kids_fashion/services/auth_service.dart';
import 'package:vahaal_kids_fashion/services/whatsapp/whatsapp_service.dart';

// =============================================================================
// MOCK IMPLEMENTATIONS FOR PHASE 1 PIPELINE TEST
// =============================================================================
class MockAuthService implements AuthService {
  UserProfile? _currentUser;

  @override
  User? get currentAuthUser => null;

  @override
  Session? get currentSession => null;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _currentUser = UserProfile(
      id: 'cashier-001',
      email: email,
      fullName: 'Rahul Sharma',
      role: 'cashier',
      isActive: true,
    );
    return _currentUser!;
  }

  @override
  Future<UserProfile?> fetchUserProfile(String userId) async => _currentUser;

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> resetPassword(String email) async {}
}

class MockProductRepository implements ProductRepository {
  final List<Product> _products;

  MockProductRepository(this._products);

  @override
  Future<List<Product>> getProducts({
    bool includeInactive = false,
    String? category,
    String? gender,
    bool? lowStockOnly,
    String? searchQuery,
  }) async => _products;

  @override
  Future<Product> getProductById(String id) async =>
      _products.firstWhere((p) => p.id == id);

  @override
  Future<Product> addProduct(Product product, List<ProductVariant> variants) async {
    final p = product.copyWith(variants: variants);
    _products.add(p);
    return p;
  }

  @override
  Future<Product> updateProduct(Product product, List<ProductVariant> variants) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    final p = product.copyWith(variants: variants);
    if (index >= 0) _products[index] = p;
    return p;
  }

  @override
  Future<void> softDeleteProduct(String productId) async {}

  @override
  Future<void> reactivateProduct(String productId) async {}

  @override
  Future<ProductVariant?> findVariantByBarcode(String barcode) async {
    for (final p in _products) {
      for (final v in p.variants) {
        if (v.barcode == barcode || v.sku == barcode) return v;
      }
    }
    return null;
  }

  @override
  Future<List<String>> getCategories() async => ['Frocks', 'T-Shirts', 'Jeans'];
}

class MockBillRepository implements BillRepository {
  final List<Bill> savedBills = [];

  @override
  Future<Bill> createBillAtomic({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    final newBill = bill.copyWith(
      id: 'bill-${savedBills.length + 1}',
      billNumber: 'VKF-POS-100${savedBills.length + 1}',
      items: items,
      createdAt: DateTime.now(),
    );
    savedBills.add(newBill);
    return newBill;
  }

  @override
  Future<Bill> getBillById(String id) async =>
      savedBills.firstWhere((b) => b.id == id);

  @override
  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
    int page = 0,
    int pageSize = 20,
    int limit = 50,
  }) async => savedBills;

  @override
  Future<int> getBillsCount({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
  }) async => savedBills.length;

  @override
  Future<String> generateNextBillNumber() async => 'VKF-POS-1001';
}

class MockCustomerRepository implements CustomerRepository {
  final List<Customer> _customers;

  MockCustomerRepository(this._customers);

  @override
  Future<List<Customer>> getCustomers({String? searchQuery, String? sortBy}) async {
    if (searchQuery == null || searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            c.mobile.contains(searchQuery))
        .toList();
  }

  @override
  Future<Customer> getCustomerById(String id) async =>
      _customers.firstWhere((c) => c.id == id);

  @override
  Future<Customer?> getCustomerByMobile(String mobile) async {
    try {
      return _customers.firstWhere((c) => c.mobile == mobile);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    _customers.add(customer);
    return customer;
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) _customers[idx] = customer;
    return customer;
  }

  @override
  Future<List<CustomerPurchaseBill>> getCustomerBills(String customerId) async => [];

  @override
  Future<Map<String, dynamic>> getCustomerStats() async => {
        'totalCustomers': _customers.length,
        'newThisMonth': 1,
        'totalRevenue': 4500.0,
        'averagePerCustomer': 4500.0,
      };
}

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardOverview> getDashboardOverview() async => const DashboardOverview(
        todaySales: 2397.0,
        todayBillsCount: 1,
        monthSales: 2397.0,
        monthBillsCount: 1,
        totalSales: 2397.0,
        totalBillsCount: 1,
      );

  @override
  Future<List<SalesChartPoint>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
    required SalesChartGrouping grouping,
  }) async =>
      [];

  @override
  Future<List<TopSellingProduct>> getTopSellingProducts({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async =>
      [];

  @override
  Future<List<TopCustomer>> getTopCustomers({int limit = 5}) async => [];
}

// =============================================================================
// MAIN PHASE 1 PIPELINE INTEGRATION TEST
// =============================================================================
void main() {
  group(
      'Phase 1 Core Workflow Pipeline Test: Login -> Dashboard -> Products -> Variants -> Stock -> Customers -> POS Billing -> Bill',
      () {
    test('Executes complete Phase 1 flow seamlessly with business invariants',
        () async {
      // -----------------------------------------------------------------------
      // Step 1: Login
      // -----------------------------------------------------------------------
      final authService = MockAuthService();
      final authProvider = AuthProvider(authService: authService);

      expect(authProvider.isAuthenticated, isFalse);
      final loginSuccess = await authProvider.login(
        email: 'cashier@vahaal.com',
        password: 'password123',
      );
      expect(loginSuccess, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.userName, equals('Rahul Sharma'));
      expect(authProvider.userProfile?.role, equals('cashier'));

      // -----------------------------------------------------------------------
      // Step 2: Dashboard
      // -----------------------------------------------------------------------
      final dashboardRepo = MockDashboardRepository();
      final dashboardProvider = DashboardProvider(repository: dashboardRepo);
      await dashboardProvider.loadDashboard();
      expect(dashboardProvider.overview, isNotNull);
      expect(dashboardProvider.overview.todaySales, equals(2397.0));

      // -----------------------------------------------------------------------
      // Step 3 & 4: Products & Product Variants
      // -----------------------------------------------------------------------
      final variant2Y = const ProductVariant(
        id: 'var-2y',
        productId: 'prod-frock',
        size: '2Y',
        color: 'Pink',
        sku: 'FRK-2Y-PINK',
        barcode: '890123456001',
        stockQuantity: 5,
        lowStockAlert: 3,
        sellingPrice: 799.0,
      );

      final variant3Y = const ProductVariant(
        id: 'var-3y',
        productId: 'prod-frock',
        size: '3Y',
        color: 'Pink',
        sku: 'FRK-3Y-PINK',
        barcode: '890123456002',
        stockQuantity: 8,
        lowStockAlert: 3,
        sellingPrice: 799.0,
      );

      final variant4Y = const ProductVariant(
        id: 'var-4y',
        productId: 'prod-frock',
        size: '4Y',
        color: 'Pink',
        sku: 'FRK-4Y-PINK',
        barcode: '890123456003',
        stockQuantity: 3,
        lowStockAlert: 3,
        sellingPrice: 849.0, // variant specific price override
      );

      final kidsFrock = Product(
        id: 'prod-frock',
        sku: 'FRK-PINK-MAIN',
        productName: 'Kids Floral Frock',
        category: 'Frocks',
        brand: 'Vahaal Kids',
        gender: 'Girl',
        purchasePrice: 400.0,
        sellingPrice: 799.0,
        variants: [variant2Y, variant3Y, variant4Y],
      );

      final productRepo = MockProductRepository([kidsFrock]);
      final productProvider = ProductProvider(repository: productRepo);
      await productProvider.loadProducts();

      // Product does not store a raw single stock, aggregates from variants
      expect(productProvider.products.length, equals(1));
      expect(kidsFrock.variantCount, equals(3));
      expect(kidsFrock.totalStock, equals(16)); // 5 + 8 + 3

      // -----------------------------------------------------------------------
      // Step 5: Stock
      // -----------------------------------------------------------------------
      // Verify variant 3Y stock before sale
      expect(variant3Y.stockQuantity, equals(8));
      expect(variant3Y.isLowStock, isFalse);
      expect(variant4Y.isLowStock, isTrue); // 3 <= lowStockAlert (3)

      // -----------------------------------------------------------------------
      // Step 6: Customers
      // -----------------------------------------------------------------------
      final customer = const Customer(
        id: 'cust-101',
        name: 'Pooja Patel',
        mobile: '9876543210',
        address: 'Adajan, Surat',
        totalPurchase: 4500.0,
        billsCount: 3,
        lastDiscount: 50.0, // customer has a saved discount memory of ₹50
      );

      final customerRepo = MockCustomerRepository([customer]);
      final customerProvider = CustomerProvider(repository: customerRepo);
      await customerProvider.loadCustomers();
      expect(customerProvider.customers.length, equals(1));

      // -----------------------------------------------------------------------
      // Step 7: POS Billing (Barcode -> Variant -> Price -> Stock -> Cart)
      // -----------------------------------------------------------------------
      final billRepo = MockBillRepository();
      final billProvider = BillProvider(repository: billRepo);

      // A. Select Customer -> Auto loads customer's discount memory
      billProvider.setCustomer(customer);
      expect(billProvider.selectedCustomer?.name, equals('Pooja Patel'));
      expect(billProvider.discountValue, equals(50.0)); // Auto-applied last discount!

      // B. Barcode resolution -> Variant 3Y
      final scannedVariant = await productRepo.findVariantByBarcode('890123456002');
      expect(scannedVariant, isNotNull);
      expect(scannedVariant!.size, equals('3Y'));
      expect(scannedVariant.color, equals('Pink'));

      // Add 2 units of Variant 3Y to Cart
      billProvider.addItem(
        product: kidsFrock,
        variant: scannedVariant,
        quantity: 2,
      );

      expect(billProvider.totalUniqueItems, equals(1));
      expect(billProvider.totalQuantity, equals(2));
      expect(billProvider.subtotal, equals(1598.0)); // 2 * 799.0

      // Add 1 unit of Variant 4Y (price override 849.0)
      billProvider.addItem(
        product: kidsFrock,
        variant: variant4Y,
        quantity: 1,
      );

      expect(billProvider.totalUniqueItems, equals(2));
      expect(billProvider.totalQuantity, equals(3));
      expect(billProvider.subtotal, equals(2447.0)); // 1598 + 849

      // Effective Discount calculation
      expect(billProvider.effectiveDiscount, equals(50.0));
      expect(billProvider.grandTotal, equals(2397.0)); // 2447 - 50

      // Select Payment Method
      billProvider.setPaymentMethod('upi');
      expect(billProvider.paymentMethod, equals('upi'));

      // -----------------------------------------------------------------------
      // Step 8: Bill Generation & Finalization
      // -----------------------------------------------------------------------
      final generatedBill =
          await billProvider.checkout(cashierId: authProvider.userProfile?.id);

      expect(generatedBill, isNotNull);
      expect(generatedBill!.billNumber, equals('VKF-POS-1001'));
      expect(generatedBill.items.length, equals(2));
      expect(generatedBill.grandTotal, equals(2397.0));
      expect(generatedBill.paymentMethod, equals('upi'));
      expect(generatedBill.customerNameSnapshot, equals('Pooja Patel'));

      // Verify line items preserved variant snapshots
      final item1 = generatedBill.items.firstWhere((i) => i.sizeSnapshot == '3Y');
      expect(item1.productNameSnapshot, equals('Kids Floral Frock'));
      expect(item1.colorSnapshot, equals('Pink'));
      expect(item1.skuSnapshot, equals('FRK-3Y-PINK'));
      expect(item1.quantity, equals(2));
      expect(item1.unitPrice, equals(799.0));

      final item2 = generatedBill.items.firstWhere((i) => i.sizeSnapshot == '4Y');
      expect(item2.sizeSnapshot, equals('4Y'));
      expect(item2.unitPrice, equals(849.0));

      // Verify cart was reset for next customer
      expect(billProvider.isCartEmpty, isTrue);

      // Verify WhatsApp message format builder
      final waService = StandardWhatsAppService();
      final waMessage = waService.formatWhatsAppMessage(generatedBill);
      expect(waMessage, contains('Pooja Patel'));
      expect(waMessage, contains('VKF-POS-1001'));
      expect(waMessage, contains('2,397.00'));
      expect(waMessage.toLowerCase(), contains('vahaal'));
    });
  });
}
