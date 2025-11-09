class PurchaseRecord {
  final String id;
  final DateTime date;
  final List<PurchaseItem> items;
  final double total;
  final String email;
  final String? userId;  // ← ADD THIS

  PurchaseRecord({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.email,
    this.userId,  // ← ADD THIS
  });

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      items: ((json['items'] as List?) ?? [])
          .map((item) => PurchaseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      email: json['email'] as String,
      userId: json['user_id'] as String?,  // ← ADD THIS
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'email': email,
      'user_id': userId,  // ← ADD THIS
    };
  }
}

class PurchaseItem {
  final String id;
  final String title;
  final String category;
  final int quantity;
  final double price;

  PurchaseItem({
    required this.id,
    required this.title,
    required this.category,
    required this.quantity,
    required this.price,
  });

  double get subtotal => price * quantity;

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'quantity': quantity,
      'price': price,
    };
  }
}
