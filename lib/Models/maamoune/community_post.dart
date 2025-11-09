class CommunityPost {
  final String postId;
  final String communityId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final List<String> likes;

  CommunityPost({
    required this.postId,
    required this.communityId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.likes = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      postId: json['post_id'] ?? '',
      communityId: json['community_id'] ?? '',
      authorId: json['author_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      likes: List<String>.from(json['likes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'community_id': communityId,
    'author_id': authorId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'likes': likes,
  };
}
