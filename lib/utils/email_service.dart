import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> sendPurchaseEmail({
  required String email,
  required List<Map<String, dynamic>> items,
  required double total,
}) async {
  try {
    final supabase = Supabase.instance.client;

    print('📧 Sending purchase email to: $email');

    // Build items list for email
    final itemsList = items.map((item) {
      return {
        'title': item['title'],
        'category': item['category'],
        'quantity': item['qty'],
        'price': item['price'],
        'subtotal': item['price'] * item['qty'],
      };
    }).toList();

    // Call Supabase Edge Function to send email
    final response = await supabase.functions.invoke(
      'send-purchase-email',
      body: {
        'email': email,
        'items': itemsList,
        'total': total,
        'currency': '€',
      },
    );

    print('📧 Email response status: ${response.status}');
    print('📧 Email response data: ${response.data}');

    if (response.status == 200) {
      final data = response.data;
      final success = data['success'] == true;

      if (success) {
        print('✅ Email sent successfully');
      } else {
        print('❌ Email sending failed: ${data['message']}');
      }

      return success;
    } else {
      print('❌ Email service returned error status: ${response.status}');
      return false;
    }
  } catch (e, stackTrace) {
    print('❌ Error sending email: $e');
    print('❌ Stack trace: $stackTrace');
    return false;
  }
}