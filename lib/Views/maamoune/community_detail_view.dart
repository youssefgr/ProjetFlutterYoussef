import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/maamoune/community.dart';
import '../../viewmodels/maamoune/community_post_view_model.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;
  final String currentUserId;

  const CommunityDetailScreen({
    super.key,
    required this.community,
    required this.currentUserId,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityPostViewModel>().fetchPosts(widget.community.communityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityPostViewModel>();
    final posts = viewModel.posts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.community.name),
      ),
      body: Column(
        children: [
          // 🧾 Community Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Text(widget.community.description),
          ),
          const Divider(),

          // 💬 Posts List
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final isLiked = post.likes.contains(widget.currentUserId);

                return ListTile(
                  title: Text(post.content),
                  subtitle: Text(
                    '${post.likes.length} likes • ${post.createdAt.toLocal()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
                    onPressed: () => viewModel.toggleLike(
                      post.postId,
                      widget.currentUserId,
                      widget.community.communityId,
                    ),
                  ),
                );
              },
            ),
          ),

          // 📝 Add Post
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'Share an update...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_postController.text.isNotEmpty) {
                      viewModel.createPost(
                        widget.community.communityId,
                        widget.currentUserId,
                        _postController.text,
                      );
                      _postController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
