/// Application Route Names
class AppRoutes {
  AppRoutes._();

  // Root & Authentication
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  // POS
  static const String pos = '/pos';

  // Bills
  static const String bills = '/bills';
  static const String billDetails = '/bills/details';

  // Products
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String productDetails = '/products/details';
  static const String editProduct = '/products/edit';
  static const String labelPrint = '/products/labels';

  // Stock
  static const String stock = '/stock'; // Stock Overview
  static const String stockIn = '/stock/in';
  static const String stockAdjustment = '/stock/adjustment';
  static const String stockHistory = '/stock/history';
  static const String lowStock = '/stock/low-stock';

  // Customers
  static const String customers = '/customers';
  static const String addCustomer = '/customers/add';
  static const String customerDetails = '/customers/details';
  static const String editCustomer = '/customers/edit';

  // Reports
  static const String reports = '/reports';

  // Settings
  static const String settings = '/settings';
}
