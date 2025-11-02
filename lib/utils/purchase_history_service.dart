import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projetflutteryoussef/Models/Youssef/purchase_history.dart';

class PurchaseHistoryService {
  static const String _storageKey = 'purchase_history';

  // Save a new purchase
  static Future<bool> savePurchase({
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String email,
    String? userId,
  }) async {
    try {
      print('💾 Saving purchase to history...');

      // Create purchase record
      final purchase = PurchaseRecord(
        id: 'PUR-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        items: cartItems.map((item) {
          return PurchaseItem(
            id: item['id'],
            title: item['title'],
            category: item['category'],
            quantity: item['qty'],
            price: item['price'].toDouble(),
          );
        }).toList(),
        total: total,
        email: email,
        userId: userId,
      );

      // Get existing history
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);

      List<PurchaseRecord> history = [];
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        history = decoded.map((json) => PurchaseRecord.fromJson(json)).toList();
      }

      // Add new purchase
      history.insert(0, purchase); // Most recent first

      // Save back to storage
      final encoded = jsonEncode(history.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);

      print('✅ Purchase saved: ${purchase.id}');
      return true;
    } catch (e) {
      print('❌ Error saving purchase: $e');
      return false;
    }
  }

  // Get all purchases
  static Future<List<PurchaseRecord>> getAllPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);

      if (historyJson == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((json) => PurchaseRecord.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error loading purchases: $e');
      return [];
    }
  }

  // Clear all history (useful for testing)
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    print('🗑️ Purchase history cleared');
  }

  // Get total spending
  static Future<double> getTotalSpending() async {
    final purchases = await getAllPurchases();

    // Await all totals, resolving potential Future<double>s
    final totals = await Future.wait(purchases.map((purchase) async => purchase.total));

    // Now sum all resolved doubles
    double sum = 0.0;
    for (var total in totals) {
      sum += total;
    }
    return sum;

  }



  // Get purchase count
  static Future<int> getPurchaseCount() async {
    final purchases = await getAllPurchases();
    return purchases.length;
  }

  // Link purchases to user (for future Supabase integration)
  static Future<void> linkPurchasesToUser(String userId) async {
    try {
      final purchases = await getAllPurchases();

      // Update all purchases with userId
      final updatedPurchases = purchases.map((purchase) {
        return PurchaseRecord(
          id: purchase.id,
          date: purchase.date,
          items: purchase.items,
          total: purchase.total,
          email: purchase.email,
          userId: userId,
        );
      }).toList();

      // Save back
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(updatedPurchases.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, encoded);

      print('✅ Linked ${purchases.length} purchases to user: $userId');
    } catch (e) {
      print('❌ Error linking purchases: $e');
    }
  }
}