import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesDelete extends StatelessWidget {
  final Expenses expense;
  final VoidCallback onDelete;

  const ExpensesDelete({
    super.key,
    required this.expense,
    required this.onDelete,
  });
  Future<void> _deleteExpense(BuildContext context) async {
    try {
      // Supprime l'image liée dans le storage si elle existe
      if (expense.imageURL.isNotEmpty) {
        await ImageUtils.deleteImage(expense.imageURL);
      }

      // Supprime la dépense dans Supabase
      await Supabase.instance.client
          .from('Expenses')
          .delete()
          .eq('id', expense.id);

      // Appelle le callback onDelete (mise à jour UI ou re-fetch)
      onDelete();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${expense.title}" supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Supprimer la dépense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Êtes-vous sûr de vouloir supprimer "${expense.title}" ?',
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
            'Cette action est irréversible.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _deleteExpense(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}
