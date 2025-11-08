import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/Youssef/purchase_history.dart';

class PurchaseHistoryService {
  static final _supabase = Supabase.instance.client;
  static const String _table = 'purchase_history';

  // ✨ SAVE PURCHASE TO SUPABASE WITH USER ID
  static Future<bool> savePurchaseToSupabase({
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String email,
    required String userId,
  }) async {
    try {
      print('💾 Saving purchase to Supabase for user: $userId');

      final purchaseId = 'PUR-${DateTime.now().millisecondsSinceEpoch}';

      // Create the purchase record
      await _supabase.from(_table).insert({
        'id': purchaseId,
        'user_id': userId,  // ← KEY: Store user ID
        'email': email,
        'total': total,
        'items': cartItems,
        'purchase_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Purchase saved to Supabase for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error saving purchase: $e');
      return false;
    }
  }

  // ✨ GET PURCHASES FOR CURRENT USER ONLY
  static Future<List<Map<String, dynamic>>> getPurchasesForUser(String userId) async {
    try {
      print('📋 Loading purchases for user: $userId');

      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)  // ← FILTER BY USER ID
          .order('purchase_date', ascending: false);

      print('📋 Found ${response.length} purchases for user: $userId');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error loading purchases: $e');
      return [];
    }
  }

  // ✨ GET TOTAL SPENDING FOR USER
  static Future<double> getTotalSpendingForUser(String userId) async {
    try {
      final purchases = await getPurchasesForUser(userId);
      double sum = 0.0;
      for (var purchase in purchases) {
        sum += (purchase['total'] as num).toDouble();
      }
      return sum;
    } catch (e) {
      print('❌ Error calculating total: $e');
      return 0.0;
    }
  }

  // ✨ GET PURCHASE COUNT FOR USER (SIMPLE)
  static Future<int> getPurchaseCountForUser(String userId) async {
    try {
      final purchases = await getPurchasesForUser(userId);
      return purchases.length;
    } catch (e) {
      print('❌ Error getting purchase count: $e');
      return 0;
    }
  }

  // ✨ DELETE PURCHASE
  static Future<bool> deletePurchase(String purchaseId, String userId) async {
    try {
      await _supabase
          .from(_table)
          .delete()
          .eq('id', purchaseId)
          .eq('user_id', userId);  // ← Only delete own purchases

      print('🗑️ Purchase deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting purchase: $e');
      return false;
    }
  }
}
