import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  static final _supabase = Supabase.instance.client;
  static const String _table = 'Expenses';

  // ✨ DECREASE STOCK AFTER PURCHASE
  static Future<bool> decreaseStock(String expenseId, int quantitySold) async {
    try {
      print('📦 Decreasing stock for expense $expenseId by $quantitySold');

      // Get current quantity
      final response = await _supabase
          .from(_table)
          .select('amount')
          .eq('id', expenseId)
          .single();

      // ✨ KEEP AS DOUBLE - amount is stored as double in database!
      double currentAmount = (response['amount'] as num).toDouble();
      double newAmount = (currentAmount - quantitySold).clamp(0.0, currentAmount);

      print('📊 Current: $currentAmount, Sold: $quantitySold, New: $newAmount');

      // Update quantity
      await _supabase
          .from(_table)
          .update({'amount': newAmount})
          .eq('id', expenseId);

      print('✅ Stock updated successfully! New amount: $newAmount');
      return true;
    } catch (e) {
      print('❌ Error decreasing stock: $e');
      return false;
    }
  }

  // ✨ CHECK IF ITEM IS IN STOCK - FIXED VERSION
  static Future<bool> isInStock(String expenseId, int requiredQuantity) async {
    try {
      print('\n🔍 === STOCK CHECK START ===');
      print('📍 Checking expense ID: "$expenseId"');
      print('📍 Required quantity: $requiredQuantity');

      // ✨ MAKE SURE expenseId IS A STRING (it might be coming as int!)
      String idToCheck = expenseId.toString();
      print('📍 ID as string: "$idToCheck"');

      // ✨ TRY TO GET THE ITEM
      final response = await _supabase
          .from(_table)
          .select('id, amount, title')
          .eq('id', idToCheck)
          .maybeSingle();  // ✨ Use maybeSingle instead of single to avoid errors

      // ✨ IF NO RESPONSE, ITEM NOT FOUND
      if (response == null) {
        print('❌ ITEM NOT FOUND IN DATABASE!');
        print('⚠️ The ID "$idToCheck" does not exist!');
        print('🔍 === STOCK CHECK END (FAILED) ===\n');
        return false;
      }

      print('📋 Response from DB: $response');

      // ✨ KEEP AS DOUBLE - Compare double to double correctly
      double currentAmount = (response['amount'] as num).toDouble();
      String title = response['title'] ?? 'Unknown';

      bool inStock = currentAmount >= requiredQuantity;

      print('📦 Product: $title');
      print('📦 Available: $currentAmount');
      print('📦 Required: $requiredQuantity');
      print('📦 In Stock: $inStock');

      if (!inStock) {
        print('⚠️ STOCK INSUFFICIENT! Need $requiredQuantity but only have $currentAmount');
      } else {
        print('✅ STOCK OK! Can proceed with purchase');
      }

      print('🔍 === STOCK CHECK END ===\n');

      return inStock;
    } catch (e) {
      print('❌ ERROR checking stock: $e');
      print('🔍 === STOCK CHECK END (ERROR) ===\n');
      return false;
    }
  }

  // ✨ GET CURRENT STOCK (returns as double to maintain precision)
  static Future<double> getStock(String expenseId) async {
    try {
      print('📦 Getting stock for expense: $expenseId');

      String idToCheck = expenseId.toString();

      final response = await _supabase
          .from(_table)
          .select('amount')
          .eq('id', idToCheck)
          .maybeSingle();

      if (response == null) {
        print('❌ Expense not found: $idToCheck');
        return 0.0;
      }

      double amount = (response['amount'] as num).toDouble();
      print('📦 Current stock: $amount');
      return amount;
    } catch (e) {
      print('❌ Error getting stock: $e');
      return 0.0;
    }
  }

  // ✨ GET STOCK AS INT (for display purposes - rounds down)
  static Future<int> getStockAsInt(String expenseId) async {
    final stock = await getStock(expenseId);
    return stock.toInt();
  }

  // ✨ DEBUG: Get ALL expenses from DB to verify data
  static Future<void> debugPrintAllExpenses() async {
    try {
      print('\n🔍 === ALL EXPENSES IN DATABASE ===');
      final response = await _supabase
          .from(_table)
          .select('id, title, amount, price');

      print('Total expenses: ${response.length}');
      for (var item in response) {
        print('  - ID: ${item['id']} (type: ${item['id'].runtimeType}), Title: ${item['title']}, Amount: ${item['amount']}, Price: ${item['price']}');
      }
      print('🔍 === END ===\n');
    } catch (e) {
      print('❌ Error printing expenses: $e');
    }
  }
}
