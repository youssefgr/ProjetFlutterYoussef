import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_enum_you.dart';
import 'package:projetflutteryoussef/Views/Youssef/Cart/cart_manager.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'package:provider/provider.dart';
import 'expenses_delete.dart';
import 'package:projetflutteryoussef/Views/Youssef/Expenses%20Crud/expenses_edit.dart';
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpensesEdit(
                    expense: _currentExpense,
                  ),
                ),
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
                    if (widget.onDelete != null) {
                      widget.onDelete!(_currentExpense.id);
                    }
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExpenseImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentExpense.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryBadge(),
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: '${_currentExpense.date.day}/${_currentExpense.date.month}/${_currentExpense.date.year}',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.shopping_bag,
                    label: 'Quantité',
                    value: _currentExpense.amount.toStringAsFixed(0),
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.euro,
                    label: 'Prix',
                    value: '${_currentExpense.price.toStringAsFixed(2)} €',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.person,
                    label: 'Utilisateur',
                    value: _currentExpense.userId,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _showAddToCartDialog(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseImage() {
    if (_currentExpense.imageURL.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No Image Available',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Image.network(
              _currentExpense.imageURL,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _getCategoryColor().withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _currentExpense.category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.15),
        border: Border.all(
          color: _getCategoryColor(),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _currentExpense.category.name,
        style: TextStyle(
          color: _getCategoryColor(),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (_currentExpense.category) {
      case ExpensesCategory.Manga:
        return Colors.red;
      case ExpensesCategory.Merchandise:
        return Colors.blue;
      case ExpensesCategory.EventTicket:
        return Colors.green;
    }
  }

  // ✨ FIXED - Create controller inside dialog, dispose on close ONLY
  void _showAddToCartDialog(BuildContext context) {
    TextEditingController? qtyController;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // ✨ Create controller INSIDE builder
        qtyController = TextEditingController(text: "1");

        return AlertDialog(
          title: const Text('Add to Cart'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: ${_currentExpense.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Enter quantity to add:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Max: ${_currentExpense.amount.toInt()} available',
                    prefixIcon: const Icon(Icons.shopping_bag),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Price: ${_currentExpense.price.toStringAsFixed(2)} € per unit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // ✨ Dispose before closing
                qtyController?.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add'),
              onPressed: () {
                final qty = int.tryParse(qtyController?.text ?? '0') ?? 0;

                if (qty <= 0 || qty > _currentExpense.amount.toInt()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a quantity between 1 and ${_currentExpense.amount.toInt()}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // ✨ GET CART FROM PROVIDER
                final cart = Provider.of<CartManager>(context, listen: false);

                // ✨ ADD ITEM WITH QUANTITY
                cart.addToCart(
                  _currentExpense.id,
                  _currentExpense.title,
                  _currentExpense.price,
                  _currentExpense.category.name,
                  qty: qty,
                );

                // ✨ Dispose before closing
                qtyController?.dispose();
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ $qty × "${_currentExpense.title}" added to cart!',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'View Cart',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartView(),
                          ),
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
