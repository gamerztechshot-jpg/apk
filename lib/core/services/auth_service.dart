// core/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fcm_token_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
        emailRedirectTo: null, // Skip email confirmation
      );

      if (response.user != null) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'name': name, 'phone': phone}),
        );
        notifyListeners();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Reset password for email - sends OTP code
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP and reset password
  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      // First verify the OTP to authenticate the user
      await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );

      // After successful verification, update the password
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Update password (for already authenticated users)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        notifyListeners();
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await FcmTokenService.unregisterUserToken();
      await _supabase.auth.signOut();
      notifyListeners(); // Notify listeners of user data change
    } catch (e) {
      rethrow;
    }
  }

  // Update user metadata (for profile changes)
  Future<void> updateUserMetadata({String? name, String? phone}) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;

      if (updateData.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(data: updateData));
        notifyListeners(); // Notify listeners of user data change
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Refresh user data and notify listeners
  Future<void> refreshUser() async {
    try {
      // Get the current session and refresh it
      final session = _supabase.auth.currentSession;
      if (session != null) {
        // The session will automatically update the current user
        notifyListeners();
      }
    } catch (e) {}
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  // Check if user has persistent session
  Future<bool> hasPersistentSession() async {
    try {
      final session = _supabase.auth.currentSession;
      return session != null;
    } catch (e) {
      return false;
    }
  }

  // Get persistent session
  Session? getPersistentSession() {
    try {
      return _supabase.auth.currentSession;
    } catch (e) {
      return null;
    }
  }
}
