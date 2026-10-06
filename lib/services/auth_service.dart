import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/user_profile_model.dart';

abstract class AuthService {
  User? get currentAuthUser;
  Session? get currentSession;
  bool get isAuthenticated;
  Stream<AuthState> get onAuthStateChange;

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile?> fetchUserProfile(String userId);

  Future<void> signOut();

  Future<void> resetPassword(String email);
}

class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase;

  SupabaseAuthService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  User? get currentAuthUser => _supabase.auth.currentUser;

  @override
  Session? get currentSession => _supabase.auth.currentSession;

  @override
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const InvalidCredentialsException('Authentication failed. No user returned.');
      }

      // Fetch the staff profile from public.user_profiles
      UserProfile? profile = await fetchUserProfile(user.id);

      // If user profile table has not synced yet, fallback to user metadata
      if (profile == null) {
        final meta = user.userMetadata ?? {};
        profile = UserProfile(
          id: user.id,
          email: user.email ?? email,
          fullName: meta['full_name'] as String? ?? email.split('@').first,
          role: meta['role'] as String? ?? 'cashier',
          isActive: true,
        );
      }

      if (!profile.isActive) {
        await _supabase.auth.signOut();
        throw const UserInactiveException();
      }

      return profile;
    } on AuthException catch (e) {
      _mapAuthException(e);
      throw AppException(e.message);
    } on SocketException {
      throw const NetworkException();
    } on AppException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('ClientException')) {
        throw const NetworkException();
      }
      throw AppException(e.toString());
    }
  }

  @override
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (_) {
      // In case table is not ready or user profile doesn't exist yet, return null
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      _mapAuthException(e);
      throw AppException(e.message);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      throw AppException(e.toString());
    }
  }

  void _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.statusCode?.toString() ?? '';

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('invalid email or password') ||
        code == '400') {
      throw const InvalidCredentialsException();
    }

    if (msg.contains('user not found')) {
      throw const UserNotFoundException();
    }

    if (msg.contains('jwt expired') || msg.contains('session expired')) {
      throw const SessionExpiredException();
    }

    if (msg.contains('network') || msg.contains('connection')) {
      throw const NetworkException();
    }
  }
}
