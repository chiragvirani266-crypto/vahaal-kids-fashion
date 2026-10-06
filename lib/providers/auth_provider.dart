import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthStatus _status = AuthStatus.initial;
  UserProfile? _userProfile;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthProvider({AuthService? authService})
      : _authService = authService ?? SupabaseAuthService() {
    _listenToAuthState();
  }

  // Getters
  AuthStatus get status => _status;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  String get userName => _userProfile?.fullName ?? 'Staff Member';
  String get userRole => _userProfile?.role.toUpperCase() ?? 'CASHIER';
  bool get isAdmin => _userProfile?.isAdmin ?? false;

  /// Initializes auth state on application startup.
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final session = _authService.currentSession;
      final authUser = _authService.currentAuthUser;

      if (session != null && authUser != null) {
        // Fetch or build the user profile
        UserProfile? profile = await _authService.fetchUserProfile(authUser.id);
        if (profile == null) {
          final meta = authUser.userMetadata ?? {};
          profile = UserProfile(
            id: authUser.id,
            email: authUser.email ?? '',
            fullName: meta['full_name'] as String? ?? authUser.email?.split('@').first ?? 'Staff',
            role: meta['role'] as String? ?? 'cashier',
            isActive: true,
          );
        }

        if (profile.isActive) {
          _userProfile = profile;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
        } else {
          await _authService.signOut();
          _userProfile = null;
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'Account is inactive. Please contact store administrator.';
        }
      } else {
        _userProfile = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null; // Do not block UI on cold start error, let user see Login
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Signs in with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _userProfile = profile;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('SignOut error: $e');
    } finally {
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clears current error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (_status == AuthStatus.error) {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    }
  }

  /// Subscribes to Supabase Auth State stream for token refresh or external events.
  void _listenToAuthState() {
    _authStateSubscription = _authService.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut || session == null) {
        if (_status != AuthStatus.unauthenticated && _status != AuthStatus.loading) {
          _userProfile = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        if (_userProfile == null) {
          _userProfile = await _authService.fetchUserProfile(session.user.id);
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
