import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../screens/analytics/sales_analytics_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/billing/bill_details_screen.dart';
import '../../screens/billing/bill_list_screen.dart';
import '../../screens/billing/billing_screen.dart';
import '../../screens/customers/add_customer_screen.dart';
import '../../screens/customers/customer_details_screen.dart';
import '../../screens/customers/customer_list_screen.dart';
import '../../screens/customers/edit_customer_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/inventory/add_product_screen.dart';
import '../../screens/inventory/edit_product_screen.dart';
import '../../screens/inventory/label_print_screen.dart';
import '../../screens/inventory/product_details_screen.dart';
import '../../screens/inventory/product_list_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/stock/low_stock_screen.dart';
import '../../screens/stock/stock_adjustment_screen.dart';
import '../../screens/stock/stock_dashboard_screen.dart';
import '../../screens/stock/stock_history_screen.dart';
import '../../screens/stock/stock_in_screen.dart';
import 'app_routes.dart';

/// Centralized Application Router
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // -----------------------------------------------------------------------
      // ROOT & AUTH
      // -----------------------------------------------------------------------
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);

      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen(), settings);

      // -----------------------------------------------------------------------
      // POS / NEW BILL
      // -----------------------------------------------------------------------
      case AppRoutes.pos:
        return _buildRoute(const BillingScreen(), settings);

      // -----------------------------------------------------------------------
      // BILLS
      // -----------------------------------------------------------------------
      case AppRoutes.bills:
        return _buildRoute(const BillListScreen(), settings);

      case AppRoutes.billDetails:
        final args = settings.arguments;
        if (args is Bill) {
          return _buildRoute(BillDetailsScreen(bill: args), settings);
        } else if (args is String) {
          return _buildRoute(BillDetailsScreen(billId: args), settings);
        } else if (args is Map) {
          return _buildRoute(
            BillDetailsScreen(
              bill: args['bill'] as Bill?,
              billId: args['billId'] as String?,
            ),
            settings,
          );
        }
        return _buildErrorRoute('BillDetails requires a Bill or billId argument');

      // -----------------------------------------------------------------------
      // PRODUCTS
      // -----------------------------------------------------------------------
      case AppRoutes.products:
        return _buildRoute(const ProductListScreen(), settings);

      case AppRoutes.addProduct:
        return _buildRoute(const AddProductScreen(), settings);

      case AppRoutes.productDetails:
        final args = settings.arguments;
        if (args is String) {
          return _buildRoute(ProductDetailsScreen(productId: args), settings);
        } else if (args is Product && args.id != null) {
          return _buildRoute(ProductDetailsScreen(productId: args.id!), settings);
        }
        return _buildErrorRoute('ProductDetails requires a productId argument');

      case AppRoutes.editProduct:
        final args = settings.arguments;
        if (args is Product) {
          return _buildRoute(EditProductScreen(product: args), settings);
        }
        return _buildErrorRoute('EditProduct requires a Product argument');

      case AppRoutes.labelPrint:
        return _buildRoute(const LabelPrintScreen(), settings);

      // -----------------------------------------------------------------------
      // STOCK
      // -----------------------------------------------------------------------
      case AppRoutes.stock:
        return _buildRoute(const StockDashboardScreen(), settings);

      case AppRoutes.stockIn:
        final args = settings.arguments;
        final variantId = args is String ? args : null;
        return _buildRoute(StockInScreen(preselectedVariantId: variantId), settings);

      case AppRoutes.stockAdjustment:
        final args = settings.arguments;
        final variantId = args is String ? args : null;
        return _buildRoute(StockAdjustmentScreen(preselectedVariantId: variantId), settings);

      case AppRoutes.stockHistory:
        final args = settings.arguments;
        final variantId = args is String ? args : null;
        return _buildRoute(StockHistoryScreen(preselectedVariantId: variantId), settings);

      case AppRoutes.lowStock:
        return _buildRoute(const LowStockScreen(), settings);

      // -----------------------------------------------------------------------
      // CUSTOMERS
      // -----------------------------------------------------------------------
      case AppRoutes.customers:
        return _buildRoute(const CustomerListScreen(), settings);

      case AppRoutes.addCustomer:
        final args = settings.arguments;
        final mobile = args is String ? args : null;
        return _buildRoute(AddCustomerScreen(initialMobile: mobile), settings);

      case AppRoutes.customerDetails:
        final args = settings.arguments;
        if (args is String) {
          return _buildRoute(CustomerDetailsScreen(customerId: args), settings);
        } else if (args is Customer && args.id != null) {
          return _buildRoute(CustomerDetailsScreen(customerId: args.id!), settings);
        }
        return _buildErrorRoute('CustomerDetails requires a customerId argument');

      case AppRoutes.editCustomer:
        final args = settings.arguments;
        if (args is Customer) {
          return _buildRoute(EditCustomerScreen(customer: args), settings);
        }
        return _buildErrorRoute('EditCustomer requires a Customer argument');

      // -----------------------------------------------------------------------
      // REPORTS
      // -----------------------------------------------------------------------
      case AppRoutes.reports:
        return _buildRoute(const SalesAnalyticsScreen(), settings);

      // -----------------------------------------------------------------------
      // SETTINGS
      // -----------------------------------------------------------------------
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);

      // -----------------------------------------------------------------------
      // UNKNOWN ROUTE FALLBACK
      // -----------------------------------------------------------------------
      default:
        return _buildErrorRoute('Route not found: ${settings.name}');
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(Widget screen, RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => screen,
      settings: settings,
    );
  }

  static MaterialPageRoute<dynamic> _buildErrorRoute(String message) {
    return MaterialPageRoute<dynamic>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 54, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
