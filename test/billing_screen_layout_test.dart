import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vahaal_kids_fashion/models/customer_model.dart';
import 'package:vahaal_kids_fashion/models/customer_purchase_bill_model.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/providers/bill_provider.dart';
import 'package:vahaal_kids_fashion/providers/customer_provider.dart';
import 'package:vahaal_kids_fashion/providers/product_provider.dart';
import 'package:vahaal_kids_fashion/repositories/bill_repository.dart';
import 'package:vahaal_kids_fashion/repositories/customer_repository.dart';
import 'package:vahaal_kids_fashion/repositories/product_repository.dart';
import 'package:vahaal_kids_fashion/screens/billing/billing_screen.dart';
import 'package:vahaal_kids_fashion/theme/app_theme.dart';

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
  Future<Product> getProductById(String id) async => _products.firstWhere((p) => p.id == id);

  @override
  Future<Product> addProduct(Product product, List<ProductVariant> variants) async => product;

  @override
  Future<Product> updateProduct(Product product, List<ProductVariant> variants) async => product;

  @override
  Future<void> softDeleteProduct(String productId) async {}

  @override
  Future<void> reactivateProduct(String productId) async {}

  @override
  Future<ProductVariant?> findVariantByBarcode(String barcode) async => null;

  @override
  Future<List<String>> getCategories() async => [];
}

class MockBillRepository implements BillRepository {
  @override
  Future<Bill> createBillAtomic({required Bill bill, required List<BillItem> items}) async => bill;

  @override
  Future<Bill> getBillById(String id) async => throw UnimplementedError();

  @override
  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
    int page = 0,
    int pageSize = 20,
    int limit = 50,
  }) async => [];

  @override
  Future<int> getBillsCount({DateTime? startDate, DateTime? endDate, String? search, String? paymentMethod}) async => 0;

  @override
  Future<String> generateNextBillNumber() async => 'VKF-POS-1001';
}

class MockCustomerRepository implements CustomerRepository {
  @override
  Future<List<Customer>> getCustomers({String? searchQuery, String? sortBy}) async => [];

  @override
  Future<Customer> getCustomerById(String id) async => throw UnimplementedError();

  @override
  Future<Customer?> getCustomerByMobile(String mobile) async => null;

  @override
  Future<Customer> addCustomer(Customer customer) async => customer;

  @override
  Future<Customer> updateCustomer(Customer customer) async => customer;

  @override
  Future<List<CustomerPurchaseBill>> getCustomerBills(String customerId) async => [];

  @override
  Future<Map<String, dynamic>> getCustomerStats() async => {};
}

void main() {
  testWidgets('BillingScreen mobile layout does not crash with BoxConstraints infinite width', (tester) async {
    final productRepo = MockProductRepository([]);
    final billRepo = MockBillRepository();
    final custRepo = MockCustomerRepository();

    final productProvider = ProductProvider(repository: productRepo);
    final billProvider = BillProvider(repository: billRepo);
    final customerProvider = CustomerProvider(repository: custRepo);

    // Set mobile viewport
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BillingScreen(isEmbedded: true),
        ),
      ),
    );

    // Verify that NO layout exception (like BoxConstraints infinite width) is thrown
    final exception = tester.takeException();
    expect(exception, isNull);
    expect(find.byType(BillingScreen), findsOneWidget);
    expect(find.text('View Cart & Pay'), findsOneWidget);
  });

  testWidgets('BillingScreen mobile layout does not overflow with cart items on narrow screens', (tester) async {
    final productRepo = MockProductRepository([]);
    final billRepo = MockBillRepository();
    final custRepo = MockCustomerRepository();

    final productProvider = ProductProvider(repository: productRepo);
    final billProvider = BillProvider(repository: billRepo);
    final customerProvider = CustomerProvider(repository: custRepo);

    // Add an item to cart
    const dummyProduct = Product(
      id: 'p1',
      sku: 'SKU1',
      productName: 'T-Shirt',
      category: 'T-Shirts',
      brand: 'Brand',
      gender: 'Boy',
      purchasePrice: 100,
      sellingPrice: 200,
      variants: [],
    );
    const dummyVariant = ProductVariant(
      id: 'v1',
      productId: 'p1',
      size: 'M',
      color: 'Blue',
      sku: 'SKU1-M',
      barcode: '123456789',
      stockQuantity: 10,
      lowStockAlert: 2,
      sellingPrice: 200,
    );
    billProvider.addItem(product: dummyProduct, variant: dummyVariant, quantity: 1);

    // Test on narrow phone screen (360px width)
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BillingScreen(isEmbedded: true),
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isNull);
    expect(find.byType(BillingScreen), findsOneWidget);
    expect(find.text('Clear Cart'), findsOneWidget);
  });
}
