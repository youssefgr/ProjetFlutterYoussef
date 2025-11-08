import 'package:supabase_flutter/supabase_flutter.dart';

// Verify reCAPTCHA v2 token on backend
Future<bool> verifyRecaptchaV2Token(String token) async {
  try {
    final supabase = Supabase.instance.client;

    print('🔐 Verifying reCAPTCHA v2 token with backend...');
    print('📤 Token (first 30 chars): ${token.substring(0, 30)}...');

    final response = await supabase.functions.invoke(
      'Captcha_function',
      body: {'token': token},
    );

    print('📡 Response status: ${response.status}');
    print('📡 Response data: ${response.data}');

    if (response.status == 200) {
      final data = response.data;
      final success = data['success'] == true;

      if (success) {
        print('✅ CAPTCHA v2 verification successful');
      } else {
        print('❌ CAPTCHA v2 verification failed');
        print('❌ Reason: ${data['message']}');
        if (data['error-codes'] != null) {
          print('❌ Error codes: ${data['error-codes']}');
        }
      }

      return success;
    } else {
      print('❌ Backend returned error status: ${response.status}');
      return false;
    }
  } catch (e, stackTrace) {
    print('❌ Error verifying CAPTCHA: $e');
    print('❌ Stack trace: $stackTrace');
    return false;
  }
}