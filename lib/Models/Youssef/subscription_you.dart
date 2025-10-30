import 'expenses_models_you.dart';

class Subscription {
 final String id;
 final String name;
 final double cost;
 final List<SubscriptionCycle> cycles;
 final DateTime nextPaymentDate;
 final String userId;

 Subscription({required this.id, required this.name, required this.cost, required this.cycles, required this.nextPaymentDate, required this.userId,});

 Map<String, dynamic> toMap() {
  return {
    'id': id,
    'name': name,
    'cost': cost,
    'cycles': cycles.map((cycle) => cycle.index).toList(),
    'nextPaymentDate': nextPaymentDate.millisecondsSinceEpoch,
    'userId': userId,
  };
}

factory Subscription.fromMap(Map<String, dynamic> map) {
return Subscription(
  id: map['id'],
  name: map['name'],
  cost: map['cost'].toDouble(),
  cycles: (map['cycles'] as List).map((index) => SubscriptionCycle.values[index]).toList(),
  nextPaymentDate: DateTime.fromMillisecondsSinceEpoch(map['nextPaymentDate']),
  userId: map['userId'],
);
}
Subscription copyWith({
  String? id,
  String? name,
  double? cost,
  List<SubscriptionCycle>? cycles,
  DateTime? nextPaymentDate,
  String? userId,
 }){
   return Subscription(
     id: id ?? this.id,
     name: name ?? this.name,
     cost: cost ?? this.cost,
     cycles: cycles ?? this.cycles,
     nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
     userId: userId ?? this.userId,
   );
}









}
