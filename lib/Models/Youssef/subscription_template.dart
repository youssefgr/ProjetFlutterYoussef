class SubscriptionTemplate {
  final String id;
  final String name;
  final String imageUrl;
  final String? category; // Optional: streaming, music, productivity, etc.

  SubscriptionTemplate({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.category,
  });

  factory SubscriptionTemplate.fromJson(Map<String, dynamic> json) {
    return SubscriptionTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String?,
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
