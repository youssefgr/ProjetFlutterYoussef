import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';

class ExpensesDelete extends StatelessWidget {
  final Expenses expense;
  final VoidCallback onDelete;

  const ExpensesDelete({
    super.key,
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${expense.title}"?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),

          if (expense.imageURL.isNotEmpty) ...[
            FutureBuilder<File?>(
              future: ImageUtils.getImageFile(expense.imageURL),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 16),
          ],

          const Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Suppression de l'image liée à la dépense
            if (expense.imageURL.isNotEmpty) {
              await ImageUtils.deleteImage(expense.imageURL);
            }

            // Exécution du callback de suppression
            onDelete();

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${expense.title}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
