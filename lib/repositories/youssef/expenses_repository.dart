import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesRepository {
  static const String _fileName = 'expenses_data.json';

  // ✨ UPLOAD IMAGE À SUPABASE
  Future<String?> uploadExpenseImage(String imagePath, String expenseTitle) async {
    try {
      final file = File(imagePath);
      final fileName =
          'expenses/${DateTime.now().millisecondsSinceEpoch}_$expenseTitle.jpg';

      final response = await Supabase.instance.client.storage
          .from('expenses')
          .upload(fileName, file);

      // Récupérer l'URL publique
      final publicUrl = Supabase.instance.client.storage
          .from('expenses')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<void> saveExpenses(List<Expenses> expensesList) async {
    try {
      final file = await _getLocalFile();
      final jsonList = expensesList.map((item) => _expenseToJson(item)).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde des dépenses : $e');
      }
    }
  }

  static Future<List<Expenses>> loadExpenses() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList.map((json) => _expenseFromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des dépenses : $e');
      }
    }
    return [];
  }

  static Map<String, dynamic> _expenseToJson(Expenses expense) {
    return {
      'id': expense.id,
      'category': expense.category.index,
      'title': expense.title,
      'date': expense.date.millisecondsSinceEpoch,
      'amount': expense.amount,
      'price': expense.price,
      'imageURL': expense.imageURL,
      'userId': expense.userId,
    };
  }

  static Expenses _expenseFromJson(Map<String, dynamic> json) {
    return Expenses(
      id: json['id'],
      title: json['title'],
      category: ExpensesCategory.values[json['category']],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      amount: (json['amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      imageURL: json['imageURL'],
      userId: json['userId'],
    );
  }

  Future<void> addExpenseToDatabase(Expenses expense) async {
    try {
      final response = await Supabase.instance.client.from('Expenses').upsert({
        'id': expense.id,
        'title': expense.title,
        'category': expense.category.name,
        'date': expense.date.toIso8601String(),
        'amount': expense.amount,
        'price': expense.price,
        'imageURL': expense.imageURL,
        'userId': expense.userId,
      });

      print('✅ Expense added successfully');
    } catch (e) {
      print('❌ Error adding expense: $e');
      throw e;
    }
  }

  Future<List<Expenses>> fetchExpensesFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('Expenses')
          .select()
          .order('date', ascending: false);

      final data = response as List;
      return data.map((json) {
        return Expenses(
          id: json['id'].toString(),
          title: json['title'],
          category: ExpensesCategory.values.firstWhere(
                (e) => e.name == json['category'],
          ),
          date: DateTime.parse(json['date']),
          amount: (json['amount'] as num).toDouble(),
          price: (json['price'] as num).toDouble(),
          imageURL: json['imageURL'] ?? '',
          userId: json['userId'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du fetch des dépenses : $e');
      }
      return [];
    }
  }

  Future<void> updateExpense(Expenses expense) async {
    try {
      await Supabase.instance.client
          .from('Expenses')
          .update({
        'title': expense.title,
        'category': expense.category.name,
        'date': expense.date.toIso8601String(),
        'amount': expense.amount,
        'price': expense.price,
        'imageURL': expense.imageURL,
        'userId': expense.userId,
      })
          .eq('id', expense.id);
    } catch (e) {
      print('❌ Error updating expense: $e');
      throw e;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await Supabase.instance.client.from('Expenses').delete().eq('id', id);
    } catch (e) {
      print('❌ Error deleting expense: $e');
      throw e;
    }
  }
}
