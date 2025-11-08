import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaGoogle {
  /// Start Google sign-in.
  /// If [selectAccount] is true, add query param to force Google's account chooser.
  static Future<bool> signUpWithGoogle({bool selectAccount = false}) async {
    try {
      if (kDebugMode) print('🔐 Starting Google sign-up...');

      final Map<String, String>? queryParams =
      selectAccount ? {'prompt': 'select_account'} : null;

      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
        queryParams: queryParams,
      );

      if (kDebugMode) print('✅ Google sign-up started');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Google sign-up error: $e');
      rethrow;
    }
  }

  static Future<void> signOutGoogle() async {
    try {
      if (kDebugMode) print('🚪 Signing out from Google...');

      await Supabase.instance.client.auth.signOut();

      if (kDebugMode) print('✅ Google sign-out successful');
    } catch (e) {
      if (kDebugMode) print('❌ Google sign-out error: $e');
      rethrow;
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return session != null;
    } catch (e) {
      if (kDebugMode) print('❌ Error checking login status: $e');
      return false;
    }
  }

  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  static String? getCurrentUserEmail() {
    return Supabase.instance.client.auth.currentUser?.email;
  }
}