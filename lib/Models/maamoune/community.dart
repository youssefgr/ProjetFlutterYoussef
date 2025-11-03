class Community {
  final String id;
  final String name;
  final String description;
  final String ownerId;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
  });

  factory Community.fromJson(Map<String, dynamic> json) => Community(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        ownerId: json['owner_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'owner_id': ownerId,
      };
}
