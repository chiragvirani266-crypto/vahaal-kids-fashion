import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'core/routes/app_navigator.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/product_provider.dart';
import 'providers/stock_provider.dart';
import 'repositories/bill_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/stock_repository.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with session persistence
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: SupabaseConstants.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  runApp(const VahaalKidsFashionApp());
}

class VahaalKidsFashionApp extends StatelessWidget {
  const VahaalKidsFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthService & AuthProvider injection
        Provider<AuthService>(
          create: (_) => SupabaseAuthService(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            authService: context.read<AuthService>(),
          ),
        ),
        // ProductRepository & ProductProvider injection
        Provider<ProductRepository>(
          create: (_) => SupabaseProductRepository(),
        ),
        ChangeNotifierProvider<ProductProvider>(
          create: (context) => ProductProvider(
            repository: context.read<ProductRepository>(),
          ),
        ),
        // StockRepository & StockProvider injection
        Provider<StockRepository>(
          create: (_) => SupabaseStockRepository(),
        ),
        ChangeNotifierProvider<StockProvider>(
          create: (context) => StockProvider(
            repository: context.read<StockRepository>(),
          ),
        ),
        // CustomerRepository & CustomerProvider injection
        Provider<CustomerRepository>(
          create: (_) => SupabaseCustomerRepository(),
        ),
        ChangeNotifierProvider<CustomerProvider>(
          create: (context) => CustomerProvider(
            repository: context.read<CustomerRepository>(),
          ),
        ),
        // BillRepository & BillProvider injection
        Provider<BillRepository>(
          create: (_) => SupabaseBillRepository(),
        ),
        ChangeNotifierProvider<BillProvider>(
          create: (context) => BillProvider(
            repository: context.read<BillRepository>(),
          ),
        ),
        // DashboardRepository & DashboardProvider injection
        Provider<DashboardRepository>(
          create: (_) => SupabaseDashboardRepository(),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) => DashboardProvider(
            repository: context.read<DashboardRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: AppNavigator.navigatorKey,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
