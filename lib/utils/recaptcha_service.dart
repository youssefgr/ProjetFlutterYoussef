import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> verifyTokenOnBackend(String token) async {
  final supabase = Supabase.instance.client;
  final accessToken = supabase.auth.currentSession?.accessToken;

  final response = await http.post(
    Uri.parse('https://dcpztcjhgbekbadfosvt.supabase.co/functions/v1/Captcha_function'),
    headers: {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({'token': token}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }
  return false;
}
