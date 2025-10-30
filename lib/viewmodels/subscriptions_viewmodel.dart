import 'package:projetflutteryoussef/Models/Youssef/expenses_enum_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/subscription_you.dart';
import 'package:projetflutteryoussef/repositories/subscriptions_repository.dart';

class SubscriptionsViewModel {
  List<Subscription> _subscriptionsList = [];
  List<Subscription> get subscriptionsList => List.unmodifiable(_subscriptionsList);

  // Callback déclenché lorsque la liste des abonnements change
  Function()? onSubscriptionsUpdated;

  // Charger les abonnements depuis le stockage local
  Future<void> loadSubscriptions() async {
    _subscriptionsList = await SubscriptionsRepository.loadSubscriptions();
    onSubscriptionsUpdated?.call();
  }

  // Ajouter un abonnement
  Future<void> addSubscription(Subscription subscription) async {
    _subscriptionsList.add(subscription);
    await SubscriptionsRepository.saveSubscriptions(_subscriptionsList);
    onSubscriptionsUpdated?.call();
  }

  // Mettre à jour un abonnement existant
  Future<void> updateSubscription(Subscription updatedSubscription) async {
    final index =
    _subscriptionsList.indexWhere((item) => item.id == updatedSubscription.id);
    if (index != -1) {
      _subscriptionsList[index] = updatedSubscription;
      await SubscriptionsRepository.saveSubscriptions(_subscriptionsList);
      onSubscriptionsUpdated?.call();
    }
  }

  // Supprimer un abonnement
  Future<void> deleteSubscription(String id) async {
    _subscriptionsList.removeWhere((item) => item.id == id);
    await SubscriptionsRepository.saveSubscriptions(_subscriptionsList);
    onSubscriptionsUpdated?.call();
  }

  // Filtrer les abonnements par cycle (SubscriptionCycle)
  List<Subscription> getSubscriptionsByCycle(SubscriptionCycle cycle) {
    return _subscriptionsList.where((sub) => sub.cycles.contains(cycle)).toList();
  }

  // Rechercher un abonnement par utilisateur
  List<Subscription> getSubscriptionsByUser(String userId) {
    return _subscriptionsList.where((sub) => sub.userId == userId).toList();
  }

  // Calculer le total des coûts
  double getTotalCost() {
    return _subscriptionsList.fold(0.0, (sum, item) => sum + item.cost);
  }
}
