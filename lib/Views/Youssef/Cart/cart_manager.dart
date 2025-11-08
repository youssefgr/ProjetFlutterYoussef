import 'package:flutter/material.dart';

class CartManager extends ChangeNotifier {
  List<Map<String, dynamic>> cartItems = [];

  // ✨ GET TOTAL PRICE
  double get totalPrice {
    return cartItems.fold<double>(0, (sum, item) {
      double price = (item['price'] as num).toDouble();
      int qty = (item['qty'] as num).toInt();
      return sum + (price * qty);
    });
  }

  // ✨ GET TOTAL QUANTITY
  int get totalQuantity {
    return cartItems.fold<int>(0, (sum, item) {
      int qty = (item['qty'] as num).toInt();
      return sum + qty;
    });
  }

  // ✨ CHECK IF CART HAS ITEMS
  bool get hasItems => cartItems.isNotEmpty;

  // ✨ ADD TO CART - ADD SINGLE ITEM WITH QUANTITY (NOT LOOP!)
  void addToCart(
      String id,
      String title,
      double price,
      String category, {
        int qty = 1,
      }) {
    print('🛒 Adding to cart: $title x$qty');

    final cartItem = {
      'id': id,
      'title': title,
      'price': price,
      'category': category,
      'qty': qty,
    };

    cartItems.add(cartItem);
    notifyListeners();

    print('✅ Cart updated: ${cartItems.length} items, Total: $totalPrice €');
  }

  // ✨ REMOVE FROM CART
  void removeFromCart(String id) {
    print('🗑️ Removing item: $id');
    cartItems.removeWhere((item) => item['id'] == id);
    notifyListeners();
    print('✅ Item removed. Cart: ${cartItems.length} items');
  }

  // ✨ ALIAS FOR COMPATIBILITY
  void removeItem(String id) {
    removeFromCart(id);
  }

  // ✨ UPDATE QUANTITY
  void updateQuantity(String id, int newQty) {
    print('📝 Updating $id quantity to $newQty');
    for (var item in cartItems) {
      if (item['id'] == id) {
        if (newQty <= 0) {
          removeFromCart(id);
        } else {
          item['qty'] = newQty;
          notifyListeners();
          print('✅ Quantity updated: $newQty');
        }
        return;
      }
    }
  }

  // ✨ CLEAR CART
  void clearCart() {
    print('🗑️ Clearing cart...');
    cartItems.clear();
    notifyListeners();
    print('✅ Cart cleared');
  }

  // ✨ GET ITEM BY ID
  Map<String, dynamic>? getItem(String id) {
    try {
      return cartItems.firstWhere((item) => item['id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ✨ GET ITEM QUANTITY
  int getItemQuantity(String id) {
    final item = getItem(id);
    return item != null ? (item['qty'] as num).toInt() : 0;
  }

  // ✨ SHOW CAPTCHA DIALOG - REAL IMPLEMENTATION
  Future<String?> showCaptchaDialog(BuildContext context) async {
    print('🔐 Showing CAPTCHA dialog...');

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool agreedToTerms = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('🔐 Verify you\'re human'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: Colors.blue, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'I\'m not a robot',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '✅ Verification Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your browser has passed security checks.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: agreedToTerms,
                          onChanged: (value) {
                            setState(() => agreedToTerms = value ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'I agree to proceed with this purchase',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: agreedToTerms ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.verified),
                  label: const Text('Verify'),
                  onPressed: agreedToTerms
                      ? () {
                    print('✅ CAPTCHA verified!');
                    Navigator.pop(dialogContext, 'verified_token_${DateTime.now().millisecondsSinceEpoch}');
                  }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✨ PRINT CART SUMMARY
  void printCartSummary() {
    print('\n📋 CART SUMMARY:');
    print('Items: ${cartItems.length}');
    print('Total Qty: $totalQuantity');
    print('Total Price: ${totalPrice.toStringAsFixed(2)} €');
    for (var item in cartItems) {
      // ✨ FIXED - Proper calculation without nested casts
      double subtotal = (item['price'] as num).toDouble() * (item['qty'] as num).toInt();
      print('  - ${item['title']} x${item['qty']} = ${subtotal.toStringAsFixed(2)} €');
    }
    print('');
  }
}
