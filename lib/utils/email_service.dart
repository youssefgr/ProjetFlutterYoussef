import 'package:supabase_flutter/supabase_flutter.dart';

const String VERIFIED_EMAIL = 'youssef.grissa@esprit.tn';

Future<bool> sendPurchaseEmail({
  required String email,
  required List<Map<String, dynamic>> items,
  required double total,
}) async {
  try {
    print('📧 Preparing purchase email...');
    print('   Customer Email: $email');
    print('   Items: ${items.length}');
    print('   Total: €${total.toStringAsFixed(2)}');

    // ✨ PREPARE ITEMS WITH PROPER TYPES
    List<Map<String, dynamic>> formattedItems = items.map((item) {
      final price = (item['price'] is num) ? item['price'] : double.tryParse(item['price'].toString()) ?? 0.0;
      final qty = (item['qty'] is num) ? item['qty'] : int.tryParse(item['qty'].toString()) ?? 1;

      return {
        'title': item['title'] ?? 'Unknown Item',
        'price': price,
        'qty': qty,
        'category': item['category'] ?? 'N/A',
      };
    }).toList();

    print('✅ Items formatted correctly');

    print('🔧 Invoking email function...');

    final response = await Supabase.instance.client.functions.invoke(
      'send-purchase-email',
      body: {
        'email': VERIFIED_EMAIL, // ✅ Verified email
        'customerEmail': email,  // ✅ Store customer email
        'items': formattedItems,
        'total': total,
        'currency': '€',
      },
    );

    print('📨 Response Status: ${response.status}');
    print('📨 Response Data: ${response.data}');

    if (response.status == 200) {
      final responseData = response.data as Map<String, dynamic>?;
      if (responseData?['success'] == true) {
        print('✅ Email sent successfully!');
        print('   Sent to: $VERIFIED_EMAIL');
        print('   Customer: $email');
        return true;
      }
    }

    print('❌ Failed to send email');
    return false;
  } catch (e) {
    print('❌ Error sending email: $e');
    return false;
  }
}
