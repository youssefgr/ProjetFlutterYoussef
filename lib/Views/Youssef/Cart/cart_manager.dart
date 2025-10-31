import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:flutter_gcaptcha_v3/web_view.dart';
import 'dart:developer';

class CartManager {
  static final CartManager _instance = CartManager._internal();

  factory CartManager() => _instance;

  CartManager._internal();

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

  double get totalPrice =>
      cartItems.fold(
        0.0,
            (sum, item) => sum + (item['price'] * item['qty']),
      );

  bool get hasItems => cartItems.isNotEmpty;

  int get itemCount => cartItems.length;
  Future<String?> showCaptchaDialog(BuildContext context) async {
    String? token;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Please verify you are human'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ReCaptchaWebView(
            url: 'https://youssefgr.github.io/projetflutteryoussef/assets/web/recaptcha.html',
            width: double.maxFinite,
            height: 300,
            onTokenReceived: (receivedToken) {
              token = receivedToken;
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );

    return token;
  }

}
