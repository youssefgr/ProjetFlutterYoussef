import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/maamoune/community_post.dart';

class CommunityPostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new post
  Future<void> createPost(CommunityPost post) async {
    try {
      print('📝 Creating post in community: ${post.communityId}');
      await _supabase.from('community_posts').insert({
        'id': post.postId,           // Main UUID primary key
        'post_id': post.postId,      // Duplicate ID field (your schema)
        'community_id': post.communityId,
        'author_id': post.authorId,
        'content': post.content,
        'likes': post.likes,
        'created_at': post.createdAt.toIso8601String(),
      });
      print('✅ Post created successfully');
    } catch (e) {
      print('❌ Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get all posts for a community
  Future<List<CommunityPost>> getPostsByCommunity(String communityId) async {
    try {
      print('📥 Fetching posts for community: $communityId');
      final response = await _supabase
          .from('community_posts')
          .select()
          .eq('community_id', communityId)
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} posts');
      return (response as List)
          .map((data) => CommunityPost.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching posts: $e');
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Like/unlike a post
  Future<void> likePost(String postId, String userId) async {
    try {
      print('❤️ Toggling like for post: $postId by user: $userId');

      // Get current post - use 'id' column (primary key)
      final response = await _supabase
          .from('community_posts')
          .select('likes')
          .eq('id', postId)
          .single();

      List<String> likes = List<String>.from(response['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
        print('💔 Unlike');
      } else {
        likes.add(userId);
        print('❤️ Like');
      }

      // Update using 'id' column
      await _supabase
          .from('community_posts')
          .update({'likes': likes})
          .eq('id', postId);

      print('✅ Like toggled successfully');
    } catch (e) {
      print('❌ Error liking post: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      print('🗑️ Deleting post: $postId');
      await _supabase
          .from('community_posts')
          .delete()
          .eq('id', postId);  // Use 'id' column
      print('✅ Post deleted successfully');
    } catch (e) {
      print('❌ Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Get a single post by ID
  Future<CommunityPost?> getPostById(String postId) async {
    try {
      final response = await _supabase
          .from('community_posts')
          .select()
          .eq('id', postId)  // Use 'id' column
          .maybeSingle();

      if (response == null) return null;
      return CommunityPost.fromMap(response);
    } catch (e) {
      print('❌ Error fetching post: $e');
      return null;
    }
  }

  /// Get post count for a community
  Future<int> getPostCount(String communityId) async {
    try {
      final response = await _supabase
          .from('community_posts')
          .select()
          .eq('community_id', communityId);
      return response.length;
    } catch (e) {
      print('❌ Error getting post count: $e');
      return 0;
    }
  }
}
