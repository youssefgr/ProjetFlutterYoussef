import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/community_post.dart';
import 'package:projetflutteryoussef/repositories/maamoune/community_post_repository.dart';

class CommunityPostViewModel extends ChangeNotifier {
  final CommunityPostRepository _repo = CommunityPostRepository();

  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch posts for a specific community
  Future<void> fetchPostsByCommunity(String communityId) async {
    _setLoading(true);
    try {
      print('🔄 Fetching posts for community: $communityId');
      _posts = await _repo.getPostsByCommunity(communityId);
      _error = null;
      print('✅ Loaded ${_posts.length} posts');
    } catch (e) {
      _error = 'Failed to fetch posts: $e';
      print('❌ Error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new post
  Future<void> createPost(CommunityPost post) async {
    _setLoading(true);
    try {
      print('📝 Creating post...');
      await _repo.createPost(post);
      await fetchPostsByCommunity(post.communityId);
      _error = null;
      print('✅ Post created and list refreshed');
    } catch (e) {
      _error = 'Failed to create post: $e';
      print('❌ Error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Like/unlike a post
  Future<void> likePost(String postId, String userId) async {
    try {
      print('❤️ Toggling like...');
      await _repo.likePost(postId, userId);

      // Update local state immediately
      final postIndex = _posts.indexWhere((p) => p.postId == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        if (post.likes.contains(userId)) {
          post.likes.remove(userId);
        } else {
          post.likes.add(userId);
        }
        notifyListeners();
      }

      _error = null;
      print('✅ Like toggled');
    } catch (e) {
      _error = 'Failed to toggle like: $e';
      print('❌ Error: $_error');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    _setLoading(true);
    try {
      print('🗑️ Deleting post...');
      await _repo.deletePost(postId);

      // Remove from local list
      _posts.removeWhere((p) => p.postId == postId);
      _error = null;
      print('✅ Post deleted');
    } catch (e) {
      _error = 'Failed to delete post: $e';
      print('❌ Error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Private helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
