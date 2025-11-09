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

  Future<void> fetchPosts(String communityId) async {
    _setLoading(true);
    try {
      _posts = await _repo.getPostsByCommunity(communityId);
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch posts: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createPost(String communityId, String authorId, String content) async {
    _setLoading(true);
    try {
      final post = CommunityPost(
        postId: 'post_${DateTime.now().millisecondsSinceEpoch}',
        communityId: communityId,
        authorId: authorId,
        content: content,
        createdAt: DateTime.now(),
      );
      await _repo.createPost(post);
      await fetchPosts(communityId);
      _error = null;
    } catch (e) {
      _error = 'Failed to create post: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleLike(String postId, String userId, String communityId) async {
    _setLoading(true);
    try {
      await _repo.likePost(postId, userId);
      await fetchPosts(communityId);
      _error = null;
    } catch (e) {
      _error = 'Failed to toggle like: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePost(String postId, String communityId) async {
    _setLoading(true);
    try {
      await _repo.deletePost(postId);
      await fetchPosts(communityId);
      _error = null;
    } catch (e) {
      _error = 'Failed to delete post: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
