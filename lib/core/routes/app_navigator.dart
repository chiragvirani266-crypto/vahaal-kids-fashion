import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import 'app_routes.dart';

/// Centralized Navigation Service
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static NavigatorState? get _state => navigatorKey.currentState;

  // ---------------------------------------------------------------------------
  // Generic Navigation Primitives
  // ---------------------------------------------------------------------------
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    BuildContext? context,
    Object? arguments,
  }) {
    if (context != null) {
      return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
    }
    return _state?.pushNamed<T>(routeName, arguments: arguments) ?? Future.value(null);
  }

  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    BuildContext? context,
    Object? arguments,
    TO? result,
  }) {
    if (context != null) {
      return Navigator.of(context).pushReplacementNamed<T, TO>(
        routeName,
        arguments: arguments,
        result: result,
      );
    }
    return _state?.pushReplacementNamed<T, TO>(
          routeName,
          arguments: arguments,
          result: result,
        ) ??
        Future.value(null);
  }

  static Future<T?> pushNamedAndRemoveUntil<T extends Object?>(
    String routeName, {
    BuildContext? context,
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    final condition = predicate ?? (route) => false;
    if (context != null) {
      return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        routeName,
        condition,
        arguments: arguments,
      );
    }
    return _state?.pushNamedAndRemoveUntil<T>(
          routeName,
          condition,
          arguments: arguments,
        ) ??
        Future.value(null);
  }

  static void pop<T extends Object?>({BuildContext? context, T? result}) {
    if (context != null) {
      Navigator.of(context).pop<T>(result);
    } else {
      _state?.pop<T>(result);
    }
  }

  static bool canPop({BuildContext? context}) {
    if (context != null) {
      return Navigator.of(context).canPop();
    }
    return _state?.canPop() ?? false;
  }

  // ---------------------------------------------------------------------------
  // Dedicated Named Destinations
  // ---------------------------------------------------------------------------
  // 1. Root & Auth
  static Future<void> toLogin({BuildContext? context}) {
    return pushNamedAndRemoveUntil(AppRoutes.login, context: context);
  }

  static Future<void> toDashboard({BuildContext? context}) {
    return pushNamedAndRemoveUntil(AppRoutes.dashboard, context: context);
  }

  // 2. Billing / New Bill
  static Future<void> toBilling({BuildContext? context}) {
    return pushNamed(AppRoutes.billing, context: context);
  }

  static Future<void> toPos({BuildContext? context}) => toBilling(context: context);

  // 3. Bills
  static Future<void> toBills({BuildContext? context}) {
    return pushNamed(AppRoutes.bills, context: context);
  }

  static Future<void> toBillDetails({
    BuildContext? context,
    Bill? bill,
    String? billId,
  }) {
    assert(bill != null || billId != null, 'Either bill or billId must be passed to toBillDetails');
    return pushNamed(
      AppRoutes.billDetails,
      context: context,
      arguments: bill ?? billId,
    );
  }

  // 4. Products
  static Future<void> toProducts({BuildContext? context}) {
    return pushNamed(AppRoutes.products, context: context);
  }

  static Future<bool?> toAddProduct({BuildContext? context}) {
    return pushNamed<bool>(AppRoutes.addProduct, context: context);
  }

  static Future<void> toProductDetails({
    BuildContext? context,
    required String productId,
  }) {
    return pushNamed(
      AppRoutes.productDetails,
      context: context,
      arguments: productId,
    );
  }

  static Future<bool?> toEditProduct({
    BuildContext? context,
    required Product product,
  }) {
    return pushNamed<bool>(
      AppRoutes.editProduct,
      context: context,
      arguments: product,
    );
  }

  static Future<void> toLabelPrint({
    BuildContext? context,
    Product? initialProduct,
    ProductVariant? initialVariant,
  }) {
    final args = (initialProduct != null || initialVariant != null)
        ? {'product': initialProduct, 'variant': initialVariant}
        : null;
    return pushNamed(AppRoutes.labelPrint, context: context, arguments: args);
  }

  // 5. Stock
  static Future<void> toStock({BuildContext? context}) {
    return pushNamed(AppRoutes.stock, context: context);
  }

  static Future<bool?> toStockIn({BuildContext? context, String? variantId}) {
    return pushNamed<bool>(
      AppRoutes.stockIn,
      context: context,
      arguments: variantId,
    );
  }

  static Future<bool?> toStockAdjustment({BuildContext? context, String? variantId}) {
    return pushNamed<bool>(
      AppRoutes.stockAdjustment,
      context: context,
      arguments: variantId,
    );
  }

  static Future<void> toStockHistory({BuildContext? context, String? variantId}) {
    return pushNamed(
      AppRoutes.stockHistory,
      context: context,
      arguments: variantId,
    );
  }

  static Future<void> toLowStock({BuildContext? context}) {
    return pushNamed(AppRoutes.lowStock, context: context);
  }

  // 6. Customers
  static Future<void> toCustomers({BuildContext? context}) {
    return pushNamed(AppRoutes.customers, context: context);
  }

  static Future<bool?> toAddCustomer({BuildContext? context, String? initialMobile}) {
    return pushNamed<bool>(
      AppRoutes.addCustomer,
      context: context,
      arguments: initialMobile,
    );
  }

  static Future<void> toCustomerDetails({
    BuildContext? context,
    required String customerId,
  }) {
    return pushNamed(
      AppRoutes.customerDetails,
      context: context,
      arguments: customerId,
    );
  }

  static Future<bool?> toEditCustomer({
    BuildContext? context,
    required Customer customer,
  }) {
    return pushNamed<bool>(
      AppRoutes.editCustomer,
      context: context,
      arguments: customer,
    );
  }

  // 7. Reports
  static Future<void> toReports({BuildContext? context}) {
    return pushNamed(AppRoutes.reports, context: context);
  }

  // 8. Settings
  static Future<void> toSettings({BuildContext? context}) {
    return pushNamed(AppRoutes.settings, context: context);
  }
}
