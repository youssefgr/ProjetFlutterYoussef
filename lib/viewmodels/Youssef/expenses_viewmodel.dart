import 'dart:io';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/repositories/youssef/expenses_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesViewModel {
  final ExpensesRepository _repository = ExpensesRepository();

  List<Expenses> _expensesList = [];
  List<Expenses> get expensesList => _expensesList;
  // ✨ ADD THESE TO YOUR EXISTING ExpensesViewModel CLASS

  List<Map<String, dynamic>> _purchaseHistory = [];
  List<Map<String, dynamic>> get purchaseHistory => _purchaseHistory;


  // Callback déclenché lorsque la liste des dépenses change
  Function()? onExpensesUpdated;

  // ✨ Charger les dépenses depuis Supabase
  Future<void> loadExpenses() async {
    try {
      final data = await Supabase.instance.client
          .from('Expenses')
          .select()
          .order('date', ascending: false);

      _expensesList = (data as List).map((json) => Expenses.fromJson(json)).toList();
      onExpensesUpdated?.call();
      print('✅ ${_expensesList.length} expenses loaded');
    } catch (e) {
      print('❌ Erreur chargement dépenses : $e');
      rethrow;
    }
  }

  // ✨ Ajouter une dépense AVEC UPLOAD D'IMAGE
  Future<void> addExpense(
      String title,
      ExpensesCategory category,
      DateTime date,
      double amount,
      double price,
      File? imageFile,
      ) async {
    try {
      String imageUrl = '';

      // Upload l'image si elle existe
      if (imageFile != null) {
        imageUrl = await _repository.uploadExpenseImage(
          imageFile.path,
          title,
        ) ?? '';

        if (imageUrl.isEmpty) {
          throw Exception('Failed to upload image');
        }
        print('✅ Image uploaded: $imageUrl');
      }

      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

      final newExpense = Expenses(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: category,
        date: date,
        amount: amount,
        price: price,
        imageURL: imageUrl,
        userId: userId,
      );

      // Sauvegarder en base de données
      await _repository.addExpenseToDatabase(newExpense);

      _expensesList.add(newExpense);
      onExpensesUpdated?.call();
      print('✅ Expense added successfully');
    } catch (e) {
      print('❌ Erreur ajout dépense : $e');
      rethrow;
    }
  }

  // ✨ Mettre à jour une dépense (avec possibilité d'image)
  Future<void> updateExpense(
      String id,
      String title,
      ExpensesCategory category,
      DateTime date,
      double amount,
      double price,
      File? newImageFile,
      String? existingImageUrl,
      ) async {
    try {
      String imageUrl = existingImageUrl ?? '';

      // Si une nouvelle image est fournie
      if (newImageFile != null) {
        imageUrl = await _repository.uploadExpenseImage(
          newImageFile.path,
          title,
        ) ?? existingImageUrl ?? '';
        print('✅ New image uploaded: $imageUrl');
      }

      // Trouver l'index et obtenir les données actuelles
      final index = _expensesList.indexWhere((item) => item.id == id);
      if (index == -1) {
        throw Exception('Expense not found');
      }

      final updatedExpense = Expenses(
        id: id,
        title: title,
        category: category,
        date: date,
        amount: amount,
        price: price,
        imageURL: imageUrl,
        userId: _expensesList[index].userId,
      );

      // Mettre à jour en base de données
      await _repository.updateExpense(updatedExpense);

      _expensesList[index] = updatedExpense;
      onExpensesUpdated?.call();
      print('✅ Expense updated successfully');
    } catch (e) {
      print('❌ Erreur mise à jour dépense : $e');
      rethrow;
    }
  }

  // ✨ Supprimer une dépense (avec suppression d'image Supabase)
  Future<void> deleteExpense(String id) async {
    try {
      final expenseIndex = _expensesList.indexWhere(
            (item) => item.id == id,
      );

      if (expenseIndex == -1) {
        throw Exception('Expense not found');
      }

      final expense = _expensesList[expenseIndex];

      // Supprimer l'image de Supabase Storage si elle existe
      if (expense.imageURL.isNotEmpty) {
        await _deleteImageFromSupabase(expense.imageURL);
        print('✅ Image deleted from storage');
      }

      // Supprimer de la base de données
      await _repository.deleteExpense(id);

      _expensesList.removeAt(expenseIndex);
      onExpensesUpdated?.call();
      print('✅ Expense deleted successfully');
    } catch (e) {
      print('❌ Erreur suppression dépense : $e');
      rethrow;
    }
  }

  // ✨ Supprimer une image de Supabase Storage
  Future<void> _deleteImageFromSupabase(String imageUrl) async {
    try {
      // Extraire le chemin du fichier à partir de l'URL
      // Format: https://xxxxx.supabase.co/storage/v1/object/public/expenses/filename
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Trouver l'index où commence le chemin du bucket
      int expensesIndex = pathSegments.indexOf('expenses');
      if (expensesIndex != -1) {
        final filePath = pathSegments.sublist(expensesIndex).join('/');

        await Supabase.instance.client.storage
            .from('expenses')
            .remove([filePath]);

        print('✅ File deleted: $filePath');
      }
    } catch (e) {
      print('⚠️ Warning: Could not delete image from storage: $e');
      // Ne pas lever d'erreur ici, car ce n'est pas critique
    }
  }

  // Récupérer les dépenses par catégorie
  List<Expenses> getExpensesByCategory(ExpensesCategory category) {
    return _expensesList.where((expense) => expense.category == category).toList();
  }

  // Récupérer les dépenses par utilisateur
  List<Expenses> getExpensesByUser(String userId) {
    return _expensesList.where((expense) => expense.userId == userId).toList();
  }

  // Montant total (quantité)
  double getTotalAmount() {
    return _expensesList.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Prix total
  double getTotalPrice() {
    return _expensesList.fold(0.0, (sum, item) => sum + item.price);
  }

  // Montant total par catégorie
  double getTotalPriceByCategory(ExpensesCategory category) {
    return _expensesList
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, item) => sum + item.price);
  }

  // Nombre de dépenses
  int getTotalExpensesCount() {
    return _expensesList.length;
  }

  // Nombre de dépenses par catégorie
  int getExpensesCountByCategory(ExpensesCategory category) {
    return _expensesList.where((expense) => expense.category == category).length;
  }

  // Rafraîchir la liste
  Future<void> refresh() async {
    await loadExpenses();
  }

  // Nettoyer les ressources
  void dispose() {
    onExpensesUpdated = null;
  }

// Load user's purchase history
  Future<void> loadPurchaseHistory() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not logged in');
        return;
      }

      _purchaseHistory = await _repository.getUserPurchaseHistory(userId);
      onExpensesUpdated?.call();
      print('✅ Loaded ${_purchaseHistory.length} purchase records');
    } catch (e) {
      print('❌ Error loading purchase history: $e');
    }
  }

// Checkout - Save cart to purchase history
  Future<bool> checkout(List<Map<String, dynamic>> cartItems) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('❌ User not logged in');
        return false;
      }

      final total = cartItems.fold<double>(
        0,
            (sum, item) => sum + (item['price'] * item['quantity']),
      );

      final success = await _repository.savePurchaseHistory(
        userId,
        cartItems,
        total,
      );

      if (success) {
        await loadPurchaseHistory(); // Refresh
      }

      return success;
    } catch (e) {
      print('❌ Error during checkout: $e');
      return false;
    }
  }

}
