import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'expenses_delete.dart';
import '../expenses_edit.dart';

class ExpensesDetail extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(expense.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesEdit(expense: expense),
                ),
              ).then((updatedExpense) {
                if (updatedExpense != null) {
                  if (onUpdate != null) {
                    onUpdate!(updatedExpense);
                  }
                  Navigator.pop(context, updatedExpense);
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ExpensesDelete(
                  expense: expense,
                  onDelete: () {
                    if (onDelete != null) {
                      onDelete!(expense.id);
                    }
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
              expense.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildInfoChip('Category', expense.category.name, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoRow(
              'Date',
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            ),
            const SizedBox(height: 16),

            _buildInfoRow('Available', expense.amount.toStringAsFixed(0)),
            const SizedBox(height: 8),

            _buildInfoRow('Price', '${expense.price.toStringAsFixed(2)} €'),
            const SizedBox(height: 16),

            _buildInfoRow('User ID', expense.userId),
          ],
        ),
      ),

      // Add to cart floating button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Add to Cart'),
        onPressed: () => _showAddToCartDialog(context),
      ),
    );
  }

  // Image display
  Widget _buildExpenseImage() {
    if (expense.imageURL.isEmpty) {
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
            Text(
              'No Image',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<File?>(
      future: ImageUtils.getImageFile(expense.imageURL),
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

  // Helper Widgets
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  // Show quantity dialog for Add to Cart
  void _showAddToCartDialog(BuildContext context) {
    final TextEditingController _qtyController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add "${expense.title}" to cart'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter quantity to add:'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Quantity (max: ${expense.amount.toInt()})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Add'),
              onPressed: () {
                final qty = int.tryParse(_qtyController.text) ?? 0;
                if (qty <= 0 || qty > expense.amount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid quantity selected!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$qty × "${expense.title}" added to cart!'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: Colors.white,
                      onPressed: () {
                        // Future navigation to cart page
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
