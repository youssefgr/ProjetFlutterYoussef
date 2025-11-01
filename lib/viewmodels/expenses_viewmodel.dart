import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesViewModel {
  List<Expenses> _expensesList = [];
  List<Expenses> get expensesList => _expensesList;

  // Callback déclenché lorsque la liste des dépenses change
  Function()? onExpensesUpdated;

  // Charger les dépenses depuis Supabase sans `.execute()`
  Future<void> loadExpenses() async {
    try {
      final data = await Supabase.instance.client
          .from('Expenses')
          .select()
          .order('date', ascending: false);

      // data est une List<dynamic> venant de Supabase
      _expensesList = (data as List).map((json) => Expenses.fromJson(json)).toList();

      onExpensesUpdated?.call();
    } catch (e) {
      print('Erreur chargement dépenses : $e');
    }
  }

  // Ajouter une dépense sans `.execute()`
  Future<void> addExpense(Expenses expense) async {
    try {
      await Supabase.instance.client
          .from('Expenses')
          .upsert({
        'id': expense.id,
        'title': expense.title,
        'category': expense.category.name,
        'date': expense.date.toIso8601String(),
        'amount': expense.amount,
        'price': expense.price,
        'imageURL': expense.imageURL,
        'userId': expense.userId,
      });

      _expensesList.add(expense);
      onExpensesUpdated?.call();
    } catch (e) {
      print('Erreur ajout dépense : $e');
    }
  }

  // Mettre à jour une dépense existante sans `.execute()`
  Future<void> updateExpense(Expenses updatedExpense) async {
    try {
      print('Update expense id: ${updatedExpense.id}');
      await Supabase.instance.client
          .from('Expenses')
          .update({
        'title': updatedExpense.title,
        'category': updatedExpense.category.name,
        'date': updatedExpense.date.toIso8601String(),
        'amount': updatedExpense.amount,
        'price': updatedExpense.price,
        'imageURL': updatedExpense.imageURL,
        'userId': updatedExpense.userId,
      })
          .eq('id', updatedExpense.id);

      final index = _expensesList.indexWhere((item) => item.id == updatedExpense.id);
      if (index != -1) {
        _expensesList[index] = updatedExpense;
        onExpensesUpdated?.call();
      }
      print('Update completed');
    } catch (e) {
      print('Erreur mise à jour dépense : $e');
    }
  }


  // Supprimer une dépense sans `.execute()`
  Future<void> deleteExpense(String id) async {
    try {
      final expense = _expensesList.firstWhere(
            (item) => item.id == id,
        orElse: () => throw Exception('Expense not found'),
      );

      if (expense.imageURL.isNotEmpty) {
        await ImageUtils.deleteImage(expense.imageURL);
      }

      // Appel Supabase pour suppression
      final _ = await Supabase.instance.client
          .from('Expenses')
          .delete()
          .eq('id', id);

      _expensesList.removeWhere((item) => item.id == id);
      onExpensesUpdated?.call();
    } catch (e) {
      print('Erreur suppression dépense : $e');
    }
  }



  // Les autres méthodes restent inchangées...

  List<Expenses> getExpensesByCategory(ExpensesCategory category) {
    return _expensesList.where((expense) => expense.category == category).toList();
  }

  List<Expenses> getExpensesByUser(String userId) {
    return _expensesList.where((expense) => expense.userId == userId).toList();
  }

  double getTotalAmount() {
    return _expensesList.fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalPrice() {
    return _expensesList.fold(0.0, (sum, item) => sum + item.price);
  }
}
