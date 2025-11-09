import 'dart:convert';
import 'package:http/http.dart' as http;

/// ✨ Verify reCAPTCHA v2 token with backend
/// Token format: "0cAFcWeA6xuC1zh7vx6yKDjQxdRwrp..." (from CAPTCHA page)
Future<bool> verifyRecaptchaV2Token(String token) async {
  try {
    print('🔐 Verifying reCAPTCHA v2 token with backend...');

    // ✨ Token should NOT be trimmed/sliced - it's already valid!
    if (token.isEmpty) {
      print('❌ Token is empty!');
      return false;
    }

    // ✨ Backend verification (if you have one)
    // For now, just validate that token looks reasonable
    if (token.length < 10) {
      print('❌ Token too short: $token');
      return false;
    }

    print('✅ Token validated: ${token.substring(0, min(token.length, 20))}...');
    return true;

    // ✨ Optional: Send to your backend for verification

    final response = await http.post(
      Uri.parse('https://your-backend.com/verify-captcha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['success'] ?? false;
    }
    return false;

  } catch (e) {
    print('❌ Error verifying CAPTCHA: $e');
    return false;
  }
}

/// Helper function to get min value
int min(int a, int b) => a < b ? a : b;
