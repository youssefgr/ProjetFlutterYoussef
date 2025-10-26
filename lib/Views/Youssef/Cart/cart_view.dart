import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}


class _CartViewState extends State<CartView> {
  final CartManager cart = CartManager(); // Access the global instance

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cart.hasItems)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear Cart',
              onPressed: () => setState(cart.clearCart),
            ),
        ],
      ),
      body: cart.cartItems.isEmpty
          ? const Center(
        child: Text(
          'No items in your cart yet!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.cartItems.length,
              itemBuilder: (context, index) {
                final item = cart.cartItems[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.lightBlueAccent,
                      child: Text(item['qty'].toString(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(item['title']),
                    subtitle: Text(
                      '${item['category']}  •  ${item['price'].toStringAsFixed(2)} € each',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_shopping_cart,
                          color: Colors.red),
                      onPressed: () {
                        setState(() => cart.removeItem(item['id']));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          _buildCartFooter(),
        ],
      ),
    );
  }

  Widget _buildCartFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${cart.totalPrice.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              cart.clearCart();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase successful!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.payment, color: Colors.white),
            label: const Text(
              'Buy Now',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
