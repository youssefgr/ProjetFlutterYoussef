import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/repositories/expenses_repository.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';



class ExpensesViewModel {
  List<Expenses> _expensesList = [];
  List<Expenses> get expensesList => _expensesList;

  // Callback déclenché lorsque la liste des dépenses change
  Function()? onExpensesUpdated;

  // Charger les dépenses depuis le stockage local
  Future<void> loadExpenses() async {
    _expensesList = await ExpensesRepository.loadExpenses();
    onExpensesUpdated?.call();
  }

  // Ajouter une dépense
  Future<void> addExpense(Expenses expense) async {
    _expensesList.add(expense);
    await ExpensesRepository.saveExpenses(_expensesList);
    onExpensesUpdated?.call();
  }

  // Mettre à jour une dépense existante
  Future<void> updateExpense(Expenses updatedExpense) async {
    final index = _expensesList.indexWhere((item) => item.id == updatedExpense.id);
    if (index != -1) {
      _expensesList[index] = updatedExpense;
      await ExpensesRepository.saveExpenses(_expensesList);
      onExpensesUpdated?.call();
    }
  }

  // Supprimer une dépense
  Future<void> deleteExpense(String id) async {
    final expense = _expensesList.firstWhere((item) => item.id == id);
    if (expense.imageURL.isNotEmpty) {
      await ImageUtils.deleteImage(expense.imageURL);
    }
    _expensesList.removeWhere((item) => item.id == id);
    await ExpensesRepository.saveExpenses(_expensesList);
    onExpensesUpdated?.call();
  }

  // Filtrer les dépenses par catégorie
  List<Expenses> getExpensesByCategory(ExpensesCategory category) {
    return _expensesList.where((expense) => expense.category == category).toList();
  }

  // Rechercher une dépense par utilisateur
  List<Expenses> getExpensesByUser(String userId) {
    return _expensesList.where((expense) => expense.userId == userId).toList();
  }

  // Calculer le total des montants
  double getTotalAmount() {
    return _expensesList.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Calculer le total du prix
  double getTotalPrice() {
    return _expensesList.fold(0.0, (sum, item) => sum + item.price);
  }
}
