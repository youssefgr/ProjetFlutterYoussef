import 'dart:ffi';

class ExpensesYou {
  final String title;
  //final Subscription subscription;
  //final int userid;
  final Float price;
  final String category;
  final DateTime date;
  final int quantity;

  ExpensesYou(this.title, this.price, this.category, this.date, this.quantity);

  @override
  String toString() {
    return 'ExpensesYou{title: $title, price: $price, category: $category, date: $date, quantity: $quantity}';

  }
}