class SubscriptionTemplate {
  final String id;
  final String name;
  final String imageUrl;
  final String category;

  SubscriptionTemplate({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
  });

  factory SubscriptionTemplate.fromJson(Map<String, dynamic> json) {
    return SubscriptionTemplate(
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'category': category,
    };
  }
}