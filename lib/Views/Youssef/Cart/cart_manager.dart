import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';

class CartManager {
  // Singleton setup
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  // The shared cart items list
  final List<Map<String, dynamic>> cartItems = [];

  void addToCart(Expenses expense, int qty) {
    final existing = cartItems.firstWhere(
          (item) => item['id'] == expense.id,
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      existing['qty'] += qty;
    } else {
      cartItems.add({
        'id': expense.id,
        'title': expense.title,
        'qty': qty,
        'price': expense.price,
        'category': expense.category.name,
      });
    }
  }

  void removeItem(String id) {
    cartItems.removeWhere((item) => item['id'] == id);
  }

  void clearCart() {
    cartItems.clear();
  }

  double get totalPrice => cartItems.fold(
    0.0,
        (sum, item) => sum + (item['price'] * item['qty']),
  );

  bool get hasItems => cartItems.isNotEmpty;
  int get itemCount => cartItems.length;
}
