class Community {
  final String communityId;
  final String name;
  final String? description;
  final List<String> memberIds;
  final List<String> adminIds;

  Community({
    required this.communityId,
    required this.name,
    this.description,
    this.memberIds = const [],
    this.adminIds = const [],
  });

  /// Check if user is a member
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is an admin
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': communityId,
      'community_id': communityId,  // This was missing!
      'name': name,
      'description': description,
      'member_ids': memberIds,
      'admin_ids': adminIds,
    };
  }

  /// Create from database map
  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      communityId: map['id'] ?? '',
      name: map['name'] ?? 'Unnamed',
      description: map['description'],
      memberIds: List<String>.from(map['member_ids'] ?? []),
      adminIds: List<String>.from(map['admin_ids'] ?? []),
    );
  }

  /// Copy with changes
  Community copyWith({
    String? communityId,
    String? name,
    String? description,
    List<String>? memberIds,
    List<String>? adminIds,
  }) {
    return Community(
      communityId: communityId ?? this.communityId,
      name: name ?? this.name,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
    );
  }

  @override
  String toString() {
    return 'Community(id: $communityId, name: $name, members: ${memberIds.length}, admins: ${adminIds.length})';
  }
}
