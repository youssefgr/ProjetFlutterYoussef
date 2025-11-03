import 'package:projetflutteryoussef/Models/maamoune/community_post.dart';
class CommunityPostRepository {
  final List<CommunityPost> _posts = [];

  void createPost(CommunityPost post) => _posts.add(post);

  List<CommunityPost> getPostsByCommunity(String communityId) =>
      _posts.where((p) => p.communityId == communityId).toList();

  void likePost(String postId, String userId) {
    final post = _posts.firstWhere((p) => p.postId == postId);
    if (post.likes.contains(userId)) {
      post.likes.remove(userId);
    } else {
      post.likes.add(userId);
    }
  }

  void deletePost(String postId) => _posts.removeWhere((p) => p.postId == postId);
}
