import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/community_post.dart';
import 'package:projetflutteryoussef/repositories/maamoune/community_post_repository.dart';

class CommunityPostViewModel extends ChangeNotifier {
  final CommunityPostRepository _repo = CommunityPostRepository();
  List<CommunityPost> _posts = [];

  List<CommunityPost> get posts => _posts;

  void fetchPosts(String communityId) {
    _posts = _repo.getPostsByCommunity(communityId);
    notifyListeners();
  }

  void createPost(String communityId, String authorId, String content) {
    final post = CommunityPost(
      postId: 'post_${DateTime.now().millisecondsSinceEpoch}',
      communityId: communityId,
      authorId: authorId,
      content: content,
      createdAt: DateTime.now(),
    );
    _repo.createPost(post);
    fetchPosts(communityId);
  }

  void toggleLike(String postId, String userId, String communityId) {
    _repo.likePost(postId, userId);
    fetchPosts(communityId);
  }

  void deletePost(String postId, String communityId) {
    _repo.deletePost(postId);
    fetchPosts(communityId);
  }
}
