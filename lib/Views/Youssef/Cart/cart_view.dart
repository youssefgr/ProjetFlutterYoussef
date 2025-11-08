import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    return Consumer<CartManager>(
      builder: (context, cart, _) {
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
                        content: const Text('Are you sure you want to clear your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              cart.clearCart();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear', style: TextStyle(color: Colors.red)),
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
                    return _buildCartItem(item, index, cart);
                  },
                ),
              ),
              _buildEmailSection(),
              _buildCartFooter(cart),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some expenses to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              backgroundColor: Colors.blue,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, CartManager cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                    ),
                    Text('×', style: TextStyle(fontSize: 12, color: Colors.blue.shade500)),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(item['category']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['category'],
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getCategoryColor(item['category'])),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item['price'].toStringAsFixed(2)} € each',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: ${(item['price'] * item['qty']).toStringAsFixed(2)} €',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                cart.removeItem(item['id']);
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
                  decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.email, size: 20, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                const Text('Email for receipt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your.email@example.com',
                prefixIcon: const Icon(Icons.alternate_email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';

                // ✅ PROPER EMAIL REGEX
                final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                );

                if (!emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email (e.g., user@example.com)';
                }
                return null;
              },

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFooter(CartManager cart) {
    final subtotal = cart.totalPrice;
    final tax = subtotal * 0.20;
    final total = subtotal + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black, width: 1)),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.black)),
              Text('${subtotal.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (20%)', style: TextStyle(fontSize: 14, color: Colors.black)),
              Text('${tax.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              Text('${total.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessing ? Colors.black : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isProcessing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.payment),
              label: Text(
                _isProcessing ? 'Processing...' : 'Proceed to Checkout',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _isProcessing ? null : () => _handlePurchase(cart),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(CartManager cart) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // ✨ GET CURRENT USER ID FROM SUPABASE
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      final String userId = supabaseUser?.id ?? 'anonymous';

      String? token = await cart.showCaptchaDialog(context);

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        final valid = await verifyRecaptchaV2Token(token);

        if (!mounted) return;

        if (valid) {
          await sendPurchaseEmail(
            email: _emailController.text.trim(),
            items: cart.cartItems,
            total: cart.totalPrice,
          );

          // ✨ SAVE TO SUPABASE (FIXED - use correct method name!)
          await PurchaseHistoryService.savePurchaseToSupabase(
            cartItems: cart.cartItems,
            total: cart.totalPrice,
            email: _emailController.text.trim(),
            userId: userId,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Purchase successful! Receipt sent to ${_emailController.text}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
            cart.clearCart();
            _emailController.clear();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
        return Colors.black;
    }
  }
}
