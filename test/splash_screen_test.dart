import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vahaal_kids_fashion/core/routes/app_navigator.dart';
import 'package:vahaal_kids_fashion/core/routes/app_routes.dart';
import 'package:vahaal_kids_fashion/models/user_profile_model.dart';
import 'package:vahaal_kids_fashion/providers/auth_provider.dart';
import 'package:vahaal_kids_fashion/screens/splash/splash_screen.dart';
import 'package:vahaal_kids_fashion/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile?> fetchUserProfile(String userId) async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}
}

void main() {
  testWidgets('SplashScreen renders and checks auth without markNeedsBuild errors', (tester) async {
    final authService = MockAuthService();
    final authProvider = AuthProvider(authService: authService);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
            AppRoutes.dashboard: (_) => const Scaffold(body: Text('Dashboard Screen')),
          },
        ),
      ),
    );

    // Initial frame rendered cleanly without any exception
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the post frame callback and timer run
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    // Navigated to login screen since not authenticated
    expect(find.text('Login Screen'), findsOneWidget);
  });
}
