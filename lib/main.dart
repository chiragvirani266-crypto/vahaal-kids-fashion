import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'repositories/product_repository.dart';
import 'screens/splash/splash_screen.dart';
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
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
