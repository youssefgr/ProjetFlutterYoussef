import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';

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
      final jsonList = expensesList.map((item) => _expenseToJson(item)).toList();
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
