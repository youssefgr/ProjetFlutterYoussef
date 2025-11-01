import 'expenses_models_you.dart';
class Expenses {
final String id;
final ExpensesCategory category;
final String title ;
final DateTime date ;
final double amount ;
final double price ;
final String imageURL;
final String userId;

Expenses({required this.id, required this.category,required this.title,required this.date,
  required this.amount,required this.price,required this.imageURL, required this.userId,});

Map<String, dynamic> toMap() {
  return {
    'id': id,
    'category': category.index,
    'title': title,
    'date': date.millisecondsSinceEpoch,
    'amount': amount,
    'price': price,
    'imageURL': imageURL,
    'userId': userId,
  };
}

factory Expenses.fromJson(Map<String, dynamic> json) {
  return Expenses(
    id: json['id'].toString(), // id peut être un int dans la BDD
    title: json['title'] ?? '',
    category: ExpensesCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['category']?.toString().toLowerCase() ?? ''),
      orElse: () => ExpensesCategory.Manga, // valeur par défaut
    ),
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    amount: (json['amount'] ?? 0).toDouble(),
    price: (json['price'] ?? 0).toDouble(),
    imageURL: json['imageURL'] ?? '',
    userId: json['userId'] ?? '',
  );
}



Expenses copyWith({
  String? id,
  ExpensesCategory? category,
  String? title,
  DateTime? date,
  double? amount,
  double? price,
  String? imageURL,
  String? userId,
}) {

  return Expenses(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    price: price ?? this.price,
    imageURL: imageURL ?? this.imageURL,
    userId: userId ?? this.userId,
  );
}


}