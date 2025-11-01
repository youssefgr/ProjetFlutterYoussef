import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'expenses_delete.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses Crud/expenses_edit.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_view.dart';

class ExpensesDetail extends StatefulWidget {
  final Expenses expense;
  final Function(Expenses)? onUpdate;
  final Function(String)? onDelete;

  const ExpensesDetail({
    super.key,
    required this.expense,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<ExpensesDetail> createState() => _ExpensesDetailState();
}

class _ExpensesDetailState extends State<ExpensesDetail> {
  late Expenses _currentExpense;

  @override
  void initState() {
    super.initState();
    _currentExpense = widget.expense;
  }

  void _handleUpdate(Expenses updatedExpense) {
    setState(() {
      _currentExpense = updatedExpense;
    });
    if (widget.onUpdate != null) {
      widget.onUpdate!(updatedExpense);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentExpense.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExpensesEdit(expense: _currentExpense)),
              ).then((updatedExpense) {
                if (updatedExpense != null && updatedExpense is Expenses) {
                  _handleUpdate(updatedExpense);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ExpensesDelete(
                  expense: _currentExpense,
                  onDelete: () {
                    if (widget.onDelete != null) widget.onDelete!(_currentExpense.id);
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close detail page after deletion
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpenseImage(),
            const SizedBox(height: 24),
            Text(
              _currentExpense.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip('Category', _currentExpense.category.name, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Date',
                '${_currentExpense.date.day}/${_currentExpense.date.month}/${_currentExpense.date.year}'),
            const SizedBox(height: 16),
            _buildInfoRow('Available', _currentExpense.amount.toStringAsFixed(0)),
            const SizedBox(height: 8),
            _buildInfoRow('Price', '${_currentExpense.price.toStringAsFixed(2)} €'),
            const SizedBox(height: 16),
            _buildInfoRow('User ID', _currentExpense.userId),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Add to Cart'),
        onPressed: () => _showAddToCartDialog(context),
      ),
    );
  }

  Widget _buildExpenseImage() {
    if (_currentExpense.imageURL.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text('No Image', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return FutureBuilder<File?>(
      future: ImageUtils.getImageFile(_currentExpense.imageURL),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              snapshot.data!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            )),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _showAddToCartDialog(BuildContext context) {
    final TextEditingController qtyController = TextEditingController(text: "1");
    final cart = CartManager();
    final scaffoldContext = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add "${_currentExpense.title}" to cart'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter quantity to add:'),
              const SizedBox(height: 10),
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Quantity (max: ${_currentExpense.amount.toInt()})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add'),
              onPressed: () {
                final qty = int.tryParse(qtyController.text) ?? 0;

                if (qty <= 0 || qty > _currentExpense.amount) {
                  scaffoldContext.showSnackBar(
                    const SnackBar(
                      content: Text('Invalid quantity selected!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                cart.addToCart(_currentExpense, qty);
                Navigator.pop(dialogContext);

                scaffoldContext.showSnackBar(
                  SnackBar(
                    content: Text('$qty × "${_currentExpense.title}" added to cart!'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CartView()),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
