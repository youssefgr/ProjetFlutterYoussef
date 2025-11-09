class CartItem {
  final String expenseId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.expenseId,
    required this.name,
    required this.price,
    this.quantity = 1, required String category,
  });

  double get total => price * quantity;

  get category => null;
}
