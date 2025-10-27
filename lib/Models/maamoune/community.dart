class Community {
  final String communityId;
  final String name;
  final String description;
  final String ownerId;

  Community({
    required this.communityId,
    required this.name,
    required this.description,
    required this.ownerId,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      communityId: json['community_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['owner_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community_id': communityId,
      'name': name,
      'description': description,
      'owner_id': ownerId,
    };
  }

  @override
  String toString() {
    return 'Community(id: $communityId, name: $name, owner: $ownerId)';
  }
}
