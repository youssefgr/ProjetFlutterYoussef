import 'package:projetflutteryoussef/Models/maamoune/community_post.dart';

class CommunityPostRepository {
  final List<CommunityPost> _posts = [];

  Future<void> createPost(CommunityPost post) async {
    _posts.add(post);
  }

  Future<List<CommunityPost>> getPostsByCommunity(String communityId) async {
    return _posts.where((p) => p.communityId == communityId).toList();
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      final post = _posts.firstWhere((p) => p.postId == postId);
      if (post.likes.contains(userId)) {
        post.likes.remove(userId);
      } else {
        post.likes.add(userId);
      }
    } catch (e) {
      // Post not found
    }
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.postId == postId);
  }

  Future<CommunityPost?> getPostById(String postId) async {
    try {
      return _posts.firstWhere((p) => p.postId == postId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updatePost(CommunityPost updatedPost) async {
    final index = _posts.indexWhere((p) => p.postId == updatedPost.postId);
    if (index != -1) {
      _posts[index] = updatedPost;
    }
  }

  Future<int> getPostCount(String communityId) async {
    return _posts.where((p) => p.communityId == communityId).length;
  }
}
