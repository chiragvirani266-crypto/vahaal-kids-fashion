import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vahaal_kids_fashion/models/analytics_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/user_profile_model.dart';
import 'package:vahaal_kids_fashion/providers/auth_provider.dart';
import 'package:vahaal_kids_fashion/providers/bill_provider.dart';
import 'package:vahaal_kids_fashion/providers/customer_provider.dart';
import 'package:vahaal_kids_fashion/providers/dashboard_provider.dart';
import 'package:vahaal_kids_fashion/providers/product_provider.dart';
import 'package:vahaal_kids_fashion/providers/stock_provider.dart';
import 'package:vahaal_kids_fashion/repositories/bill_repository.dart';
import 'package:vahaal_kids_fashion/repositories/customer_repository.dart';
import 'package:vahaal_kids_fashion/repositories/dashboard_repository.dart';
import 'package:vahaal_kids_fashion/repositories/product_repository.dart';
import 'package:vahaal_kids_fashion/repositories/stock_repository.dart';
import 'package:vahaal_kids_fashion/screens/dashboard/dashboard_screen.dart';
import 'package:vahaal_kids_fashion/services/auth_service.dart';

class MockAuthService implements AuthService {
  @override
  User? get currentAuthUser => null;
  @override
  Session? get currentSession => null;
  @override
  bool get isAuthenticated => false;
  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
  @override
  Future<UserProfile> signInWithEmail({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<UserProfile?> fetchUserProfile(String userId) async => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> resetPassword(String email) async {}
}

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardOverview> getDashboardOverview() async {
    return const DashboardOverview(
      todaySales: 1500.0,
      todayBillsCount: 2,
      monthSales: 25000.0,
      monthBillsCount: 30,
      yearSales: 150000.0,
      yearBillsCount: 180,
      totalSales: 300000.0,
      totalBillsCount: 350,
      totalCustomersCount: 75,
      totalProductsCount: 35,
      lowStockCount: 2,
      totalStockUnits: 210,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockBillRepository implements BillRepository {
  @override
  Future<Bill> createBillAtomic({required Bill bill, required List<BillItem> items}) async => bill;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockProductRepo implements ProductRepository {
  @override
  Future<List<Product>> getProducts({
    bool includeInactive = false,
    String? category,
    String? gender,
    bool? lowStockOnly,
    String? searchQuery,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockStockRepo implements StockRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockCustomerRepo implements CustomerRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('Dashboard Quick Actions excludes bottom bar items (New Bill, Products, Invoices)', (tester) async {
    // Set mobile test screen resolution
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authProvider = AuthProvider(authService: MockAuthService());
    final dashboardProvider = DashboardProvider(repository: MockDashboardRepository());
    final billProvider = BillProvider(repository: MockBillRepository());
    final productProvider = ProductProvider(repository: MockProductRepo());
    final stockProvider = StockProvider(repository: MockStockRepo());
    final customerProvider = CustomerProvider(repository: MockCustomerRepo());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<StockProvider>.value(value: stockProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify bottom bar destinations exist
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('New Bill'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    // Verify Quick Actions Section Header exists
    expect(find.text('Store Modules & Tools'), findsOneWidget);

    // Verify modules that belong in Quick Actions exist
    expect(find.text('Stock & Inventory'), findsOneWidget);
    expect(find.text('Customer Directory'), findsOneWidget);
    expect(find.text('Barcode Label Printing'), findsOneWidget);
    expect(find.text('Sales & Revenue Analytics'), findsOneWidget);
    expect(find.text('Low Stock Replenishment'), findsOneWidget);
    expect(find.text('Settings & Hardware'), findsOneWidget);

    // Verify redundant duplicate functions are REMOVED from Quick Actions
    expect(find.text('Billing & Checkout'), findsNothing);
    expect(find.text('Product Catalog & Sizes'), findsNothing);
    expect(find.text('Sales & Bills History'), findsNothing);
  });

  testWidgets('Dashboard module cards do not overflow on narrow mobile screens (360px width)', (tester) async {
    // Standard narrow mobile device size (e.g. 360 x 740)
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // ignore: avoid_print
      print('CAUGHT DETAILS:\n${details.toDiagnosticsNode().toStringDeep()}');
      originalOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    final authProvider = AuthProvider(authService: MockAuthService());
    final dashboardProvider = DashboardProvider(repository: MockDashboardRepository());
    final billProvider = BillProvider(repository: MockBillRepository());
    final productProvider = ProductProvider(repository: MockProductRepo());
    final stockProvider = StockProvider(repository: MockStockRepo());
    final customerProvider = CustomerProvider(repository: MockCustomerRepo());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<StockProvider>.value(value: stockProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all module titles render without any RenderFlex overflow exceptions
    expect(find.text('Barcode Label Printing'), findsOneWidget);
    expect(find.text('Sales & Revenue Analytics'), findsOneWidget);
    expect(find.text('Low Stock Replenishment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard Sales & Store Overview excludes analytics screen functions (This Month, This Year, Lifetime, and Charts Banner)', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final authProvider = AuthProvider(authService: MockAuthService());
    final dashboardProvider = DashboardProvider(repository: MockDashboardRepository());
    final billProvider = BillProvider(repository: MockBillRepository());
    final productProvider = ProductProvider(repository: MockProductRepo());
    final stockProvider = StockProvider(repository: MockStockRepo());
    final customerProvider = CustomerProvider(repository: MockCustomerRepo());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<StockProvider>.value(value: stockProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify real-time operational overview metrics are present
    expect(find.text("Today's Sales"), findsOneWidget);
    expect(find.text("Today's Bills"), findsOneWidget);
    expect(find.text('Total Products'), findsOneWidget);
    expect(find.text('Low Stock Products'), findsOneWidget);
    expect(find.text('Total Customers'), findsOneWidget);

    // Verify historical analytics cards are removed from dashboard
    expect(find.text('This Month Sales'), findsNothing);
    expect(find.text('This Year Sales'), findsNothing);
    expect(find.text('Total Sales (Lifetime)'), findsNothing);

    // Verify analytics banner/charts card is removed from dashboard
    expect(find.text('Sales Trends & Interactive Charts'), findsNothing);
    expect(find.text('Open Charts & Analytics'), findsNothing);
  });
}

