import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesRepository {
  static const String _fileName = 'expenses_data.json';

  // Récupère le fichier local où les données des dépenses seront stockées
  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Sauvegarde la liste des dépenses dans un fichier local
  static Future<void> saveExpenses(List<Expenses> expensesList) async {
    try {
      final file = await _getLocalFile();
      final jsonList = expensesList
          .map((item) => _expenseToJson(item))
          .toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde des dépenses : $e');
      }
    }
  }

  // Charge la liste des dépenses depuis le fichier local
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

  // Convertit un objet Expenses en JSON
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

  // Convertit un JSON en objet Expenses
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
}

Future<void> addExpenseToDatabase(Expenses expense) async {
  final response = await Supabase.instance.client.from('Expenses').upsert({
    'id': expense.id,
    'title': expense.title,
    'category': expense.category.name, // adapte si besoin
    'date': expense.date.toIso8601String(),
    'amount': expense.amount,
    'price': expense.price,
    'imageURL': expense.imageURL,
    'userId': expense.userId,
  });

  if (response.error != null) {
    // Gérer l'erreur
    print('Erreur d\'enregistrement : ${response.error!.message}');
    throw response.error!;
  }
}

Future<List<Expenses>> fetchExpensesFromSupabase() async {
  try {
    final response = await Supabase.instance.client
        .from('Expenses')
        .select()
        .order('date', ascending: false);
    final data = response as List<dynamic>;

    return data.map((json) {
      return Expenses(
        id: json['id'],
        title: json['title'],
        category: ExpensesCategory.values.firstWhere(
          (e) => e.name == json['category'],
        ),
        date: DateTime.parse(json['date']),
        amount: (json['amount'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        imageURL: json['imageURL'],
        userId: json['userId'],
      );
    }).toList();
  } catch (e) {
    if (kDebugMode) {
      print('Erreur lors du fetch des dépenses depuis Supabase : $e');
    }
    return [];
  }
}

// Update une dépense dans Supabase
Future<void> updateExpense(Expenses expense) async {
  final response = await Supabase.instance.client
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

  if (response.error != null) {
    throw response.error!;
  }
}

// Supprimer une dépense
Future<void> deleteExpense(String id) async {
  final response = await Supabase.instance.client
      .from('Expenses')
      .delete()
      .eq('id', id);

  if (response.error != null) {
    throw response.error!;
  }
}
