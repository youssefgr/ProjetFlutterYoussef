import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/utils/recaptcha_service.dart';
import 'package:projetflutteryoussef/utils/email_service.dart';
import 'package:projetflutteryoussef/utils/purchase_history_service.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/purchase_history_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  final CartManager cart = CartManager();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PurchaseHistoryView(),
                ),
              );
            },
          ),
          if (cart.hasItems)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear Cart',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart?'),
                    content: const Text(
                      'Are you sure you want to clear your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(cart.clearCart);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cart.cartItems.length,
              itemBuilder: (context, index) {
                final item = cart.cartItems[index];
                return _buildCartItem(item, index);
              },
            ),
          ),
          _buildEmailSection(),
          _buildCartFooter(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some expenses to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              backgroundColor: Colors.blue,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${item['qty']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      '×',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item['category'])
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['category'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getCategoryColor(item['category']),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item['price'].toStringAsFixed(2)} € each',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${(item['price'] * item['qty']).toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() => cart.removeItem(item['id']));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item['title']} removed from cart'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.email,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Email for receipt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your.email@example.com',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                final emailRegex =
                RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFooter() {
    final subtotal = cart.totalPrice;
    final tax = subtotal * 0.20;
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${subtotal.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (20%)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${tax.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _isProcessing ? Colors.grey.shade400 : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.payment),
              label: Text(
                _isProcessing ? 'Processing Payment...' : 'Proceed to Checkout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _isProcessing ? null : _handlePurchase,
            ),
          ),
        ],
      ),
    );
  }

  // ✨ GESTION DU PAIEMENT AVEC MISE À JOUR D'INVENTAIRE
  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      print('🛒 Initiating purchase...');

      String? token = await cart.showCaptchaDialog(context);

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Verifying security...'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );

        final valid = await verifyRecaptchaV2Token(token);

        if (!mounted) return;

        if (valid) {
          // ✨ ÉTAPE 1 : Mettre à jour l'inventaire
          print('📦 Updating inventory...');
          bool inventoryUpdated = await _updateInventory();

          if (!inventoryUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                Text('❌ Failed to update inventory. Purchase cancelled.'),
                backgroundColor: Colors.red,
              ),
            );
            if (mounted) {
              setState(() => _isProcessing = false);
            }
            return;
          }

          // ✨ ÉTAPE 2 : Envoyer l'email
          final emailSent = await sendPurchaseEmail(
            email: _emailController.text.trim(),
            items: cart.cartItems,
            total: cart.totalPrice,
          );

          // ✨ ÉTAPE 3 : Sauvegarder l'historique
          final historySaved = await PurchaseHistoryService.savePurchase(
            cartItems: cart.cartItems,
            total: cart.totalPrice,
            email: _emailController.text.trim(),
          );

          if (!mounted) return;

          if (emailSent && historySaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ Purchase successful! Receipt sent to ${_emailController.text}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            cart.clearCart();
            _emailController.clear();
            setState(() {});
          } else if (!emailSent && historySaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Purchase saved but email failed. Check history for details.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
            cart.clearCart();
            _emailController.clear();
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '⚠️ Purchase completed but failed to save. Please contact support.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Security verification failed. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CAPTCHA verification cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ✨ NOUVELLE MÉTHODE : Mettre à jour l'inventaire
  Future<bool> _updateInventory() async {
    try {
      print('🔄 Decreasing inventory for ${cart.cartItems.length} items...');

      for (var item in cart.cartItems) {
        final itemId = item['id'];
        final quantityBought = item['qty'] as int;

        print('📉 Item: ${item['title']}, Qty: $quantityBought');

        try {
          // Récupérer l'amount actuel
          final response = await Supabase.instance.client
              .from('Expenses')
              .select('amount')
              .eq('id', itemId)
              .single();

          final currentAmount = (response['amount'] as num).toDouble();
          final newAmount = currentAmount - quantityBought;

          print('   Current: $currentAmount, New: $newAmount');

          // Mettre à jour avec le nouvel amount
          await Supabase.instance.client
              .from('Expenses')
              .update({'amount': newAmount})
              .eq('id', itemId);

          print('   ✅ Updated successfully');
        } catch (e) {
          print('   ❌ Error updating item $itemId: $e');
          rethrow;
        }
      }

      print('✅ All inventory updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating inventory: $e');
      return false;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'manga':
        return Colors.red;
      case 'merchandise':
        return Colors.blue;
      case 'eventticket':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
