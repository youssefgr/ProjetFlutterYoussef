import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
// Classe de stockage des données d'abonnements'
class SubscriptionsRepository {
  static const String _fileName = 'subscriptions_data.json';

  // Récupère le fichier local où sont stockées les données d'abonnements
  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Sauvegarde la liste des abonnements dans un fichier local
  static Future<void> saveSubscriptions(List<Subscription> subscriptionList) async {
    try {
      final file = await _getLocalFile();
      final jsonList = subscriptionList.map((item) => _subscriptionToJson(item)).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde des abonnements : $e');
      }
    }
  }

  // Charge la liste des abonnements depuis le fichier local
  static Future<List<Subscription>> loadSubscriptions() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList.map((json) => _subscriptionFromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des abonnements : $e');
      }
    }
    return [];
  }

  // Convertit un objet Subscription en JSON
  static Map<String, dynamic> _subscriptionToJson(Subscription subscription) {
    return {
      'id': subscription.id,
      'name': subscription.name,
      'cost': subscription.cost,
      'cycles': subscription.cycles.map((cycle) => cycle.index).toList(),
      'nextPaymentDate': subscription.nextPaymentDate.millisecondsSinceEpoch,
      'userId': subscription.userId,
    };
  }

  // Convertit un JSON en objet Subscription
  static Subscription _subscriptionFromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      cost: (json['cost'] as num).toDouble(),
      cycles: (json['cycles'] as List).map((index) => SubscriptionCycle.values[index]).toList(),
      nextPaymentDate: DateTime.fromMillisecondsSinceEpoch(json['nextPaymentDate']),
      userId: json['userId'],
    );
  }
}
