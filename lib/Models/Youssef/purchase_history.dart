class PurchaseRecord {
  final String id;
  final DateTime date;
  final List<PurchaseItem> items;
  final double total;
  final String email;
  final String? userId; // For future Supabase integration

  PurchaseRecord({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.email,
    this.userId,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'email': email,
      'userId': userId,
    };
  }

  // Create from JSON
  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      id: json['id'],
      date: DateTime.parse(json['date']),
      items: (json['items'] as List)
          .map((item) => PurchaseItem.fromJson(item))
          .toList(),
      total: json['total'].toDouble(),
      email: json['email'],
      userId: json['userId'],
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'quantity': quantity,
      'price': price,
    };
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }

  double get subtotal => price * quantity;
}