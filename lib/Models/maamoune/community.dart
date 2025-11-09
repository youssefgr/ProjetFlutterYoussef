class Community {
  final String communityId;
  final String name;
  final String description;
  final String ownerId;
  final List<String> adminIds; // List of admin user IDs
  final List<String> memberIds; // List of member user IDs

  Community({
    required this.communityId,
    required this.name,
    required this.description,
    required this.ownerId,
    this.adminIds = const [],
    this.memberIds = const [],
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      communityId: json['community_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ownerId: json['owner_id'] ?? '',
      adminIds: json['admin_ids'] != null
          ? List<String>.from(json['admin_ids'])
          : [],
      memberIds: json['member_ids'] != null
          ? List<String>.from(json['member_ids'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community_id': communityId,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'admin_ids': adminIds,
      'member_ids': memberIds,
    };
  }

  Community copyWith({
    String? communityId,
    String? name,
    String? description,
    String? ownerId,
    List<String>? adminIds,
    List<String>? memberIds,
  }) {
    return Community(
      communityId: communityId ?? this.communityId,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => adminIds.contains(userId) || isOwner(userId);
  bool isMember(String userId) => memberIds.contains(userId) || isAdmin(userId);

  @override
  String toString() {
    return 'Community(id: $communityId, name: $name, owner: $ownerId)';
  }
}