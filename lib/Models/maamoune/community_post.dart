class CommunityPost {
  final String postId;
  final String communityId;
  final String authorId;
  final String content;
  final List<String> likes;
  final DateTime createdAt;

  CommunityPost({
    required this.postId,
    required this.communityId,
    required this.authorId,
    required this.content,
    this.likes = const [],
    required this.createdAt,
  });

  /// Convert to map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': postId,              // Primary key UUID
      'post_id': postId,         // Duplicate ID field
      'community_id': communityId,
      'author_id': authorId,
      'content': content,
      'likes': likes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from Supabase map
  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      postId: map['id'] ?? map['post_id'] ?? '',  // Try 'id' first, then 'post_id'
      communityId: map['community_id'] ?? '',
      authorId: map['author_id'] ?? '',
      content: map['content'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  /// Copy with changes
  CommunityPost copyWith({
    String? postId,
    String? communityId,
    String? authorId,
    String? content,
    List<String>? likes,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      postId: postId ?? this.postId,
      communityId: communityId ?? this.communityId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CommunityPost(id: $postId, author: $authorId, likes: ${likes.length})';
  }
}
