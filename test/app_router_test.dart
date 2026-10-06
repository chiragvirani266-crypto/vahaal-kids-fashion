import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/core/routes/app_navigator.dart';
import 'package:vahaal_kids_fashion/core/routes/app_router.dart';
import 'package:vahaal_kids_fashion/core/routes/app_routes.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/screens/analytics/sales_analytics_screen.dart';
import 'package:vahaal_kids_fashion/screens/auth/login_screen.dart';
import 'package:vahaal_kids_fashion/screens/billing/bill_details_screen.dart';
import 'package:vahaal_kids_fashion/screens/billing/bill_list_screen.dart';
import 'package:vahaal_kids_fashion/screens/billing/billing_screen.dart';
import 'package:vahaal_kids_fashion/screens/customers/customer_details_screen.dart';
import 'package:vahaal_kids_fashion/screens/customers/customer_list_screen.dart';
import 'package:vahaal_kids_fashion/screens/dashboard/dashboard_screen.dart';
import 'package:vahaal_kids_fashion/screens/inventory/add_product_screen.dart';
import 'package:vahaal_kids_fashion/screens/inventory/product_details_screen.dart';
import 'package:vahaal_kids_fashion/screens/inventory/product_list_screen.dart';
import 'package:vahaal_kids_fashion/screens/settings/settings_screen.dart';
import 'package:vahaal_kids_fashion/screens/splash/splash_screen.dart';
import 'package:vahaal_kids_fashion/screens/stock/stock_adjustment_screen.dart';
import 'package:vahaal_kids_fashion/screens/stock/stock_dashboard_screen.dart';
import 'package:vahaal_kids_fashion/screens/stock/stock_history_screen.dart';
import 'package:vahaal_kids_fashion/screens/stock/stock_in_screen.dart';

void main() {
  group('AppRoutes and AppRouter Tests', () {
    test('AppRoutes defines all required node constants', () {
      expect(AppRoutes.splash, equals('/'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.dashboard, equals('/dashboard'));
      expect(AppRoutes.pos, equals('/pos'));
      expect(AppRoutes.bills, equals('/bills'));
      expect(AppRoutes.billDetails, equals('/bills/details'));
      expect(AppRoutes.products, equals('/products'));
      expect(AppRoutes.addProduct, equals('/products/add'));
      expect(AppRoutes.productDetails, equals('/products/details'));
      expect(AppRoutes.stock, equals('/stock'));
      expect(AppRoutes.stockIn, equals('/stock/in'));
      expect(AppRoutes.stockAdjustment, equals('/stock/adjustment'));
      expect(AppRoutes.stockHistory, equals('/stock/history'));
      expect(AppRoutes.customers, equals('/customers'));
      expect(AppRoutes.customerDetails, equals('/customers/details'));
      expect(AppRoutes.reports, equals('/reports'));
      expect(AppRoutes.settings, equals('/settings'));
    });

    test('AppRouter resolves parameterless routes correctly', () {
      final routes = {
        AppRoutes.splash: SplashScreen,
        AppRoutes.login: LoginScreen,
        AppRoutes.dashboard: DashboardScreen,
        AppRoutes.pos: BillingScreen,
        AppRoutes.bills: BillListScreen,
        AppRoutes.products: ProductListScreen,
        AppRoutes.addProduct: AddProductScreen,
        AppRoutes.stock: StockDashboardScreen,
        AppRoutes.stockIn: StockInScreen,
        AppRoutes.stockAdjustment: StockAdjustmentScreen,
        AppRoutes.stockHistory: StockHistoryScreen,
        AppRoutes.customers: CustomerListScreen,
        AppRoutes.reports: SalesAnalyticsScreen,
        AppRoutes.settings: SettingsScreen,
      };

      for (final entry in routes.entries) {
        final route = AppRouter.onGenerateRoute(RouteSettings(name: entry.key))
            as MaterialPageRoute;
        final widget = route.builder(MockBuildContext());
        expect(widget.runtimeType, equals(entry.value),
            reason: 'Route ${entry.key} should produce ${entry.value}');
      }
    });

    test('AppRouter resolves parameterized routes correctly', () {
      // Bill details with billId
      final billRoute = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.billDetails, arguments: 'test-bill-id'),
      ) as MaterialPageRoute;
      expect(billRoute.builder(MockBuildContext()).runtimeType, equals(BillDetailsScreen));

      // Product details with productId
      final productRoute = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.productDetails, arguments: 'prod-123'),
      ) as MaterialPageRoute;
      expect(productRoute.builder(MockBuildContext()).runtimeType, equals(ProductDetailsScreen));

      // Customer details with customerId
      final customerRoute = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.customerDetails, arguments: 'cust-456'),
      ) as MaterialPageRoute;
      expect(customerRoute.builder(MockBuildContext()).runtimeType, equals(CustomerDetailsScreen));
    });

    test('AppNavigator exposes global navigatorKey', () {
      expect(AppNavigator.navigatorKey, isNotNull);
      expect(AppNavigator.navigatorKey, isA<GlobalKey<NavigatorState>>());
    });
  });

  group('Clothing Retail Variant & Stock Model Architecture Tests', () {
    test('Product has variants with individual stock, SKU, size, color and barcodes', () {
      const variant1 = ProductVariant(
        id: 'var-1',
        size: '2Y',
        color: 'Pink',
        sku: 'FRK-2Y-PINK',
        barcode: '890123456001',
        stockQuantity: 5,
        sellingPrice: 799.0,
      );

      const variant2 = ProductVariant(
        id: 'var-2',
        size: '3Y',
        color: 'Pink',
        sku: 'FRK-3Y-PINK',
        barcode: '890123456002',
        stockQuantity: 8,
        sellingPrice: 799.0,
      );

      const variant3 = ProductVariant(
        id: 'var-3',
        size: '4Y',
        color: 'Pink',
        sku: 'FRK-4Y-PINK',
        barcode: '890123456003',
        stockQuantity: 3,
        sellingPrice: 799.0,
      );

      const product = Product(
        id: 'prod-frock-1',
        sku: 'FRK-PINK-MAIN',
        productName: 'Kids Frock',
        category: 'Frocks',
        gender: 'Girl',
        purchasePrice: 400.0,
        sellingPrice: 799.0,
        variants: [variant1, variant2, variant3],
      );

      // Verify that product does not store raw single stock, but aggregates variants
      expect(product.totalStock, equals(16)); // 5 + 8 + 3
      expect(product.variantCount, equals(3));

      // Barcode -> Variant mapping
      final scannedBarcode = '890123456002';
      final matchingVariant = product.variants.firstWhere(
        (v) => v.barcode == scannedBarcode,
      );

      // Barcode -> Variant -> Price -> Stock
      expect(matchingVariant.size, equals('3Y'));
      expect(matchingVariant.color, equals('Pink'));
      expect(matchingVariant.sku, equals('FRK-3Y-PINK'));
      expect(matchingVariant.stockQuantity, equals(8));
      expect(matchingVariant.sellingPrice, equals(799.0));
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}
