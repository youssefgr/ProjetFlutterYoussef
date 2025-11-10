import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/maamoune/community.dart';
import '../../Models/maamoune/user.dart';
import '../../viewmodels/maamoune/community_post_view_model.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';
import '../../viewmodels/maamoune/community_viewmodel.dart';
import '../../Models/maamoune/community_post.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

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
  late Community _community;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityPostViewModel>().fetchPostsByCommunity(widget.community.communityId);
    });
  }

  bool _isAdmin() => _community.adminIds.contains(widget.currentUserId);
  bool _isMember() => _community.memberIds.contains(widget.currentUserId);

  void _publishPost() async {
    if (_postController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first!')),
      );
      return;
    }

    final newPost = CommunityPost(
      postId: const Uuid().v4(),
      communityId: widget.community.communityId,
      authorId: widget.currentUserId,
      content: _postController.text,
      createdAt: DateTime.now(),
    );

    await context.read<CommunityPostViewModel>().createPost(newPost);
    _postController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post published! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _leaveCommunity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Community'),
        content: Text('Are you sure you want to leave ${_community.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await context.read<CommunityViewModel>().leaveCommunity(
                _community.communityId,
                widget.currentUserId,
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Left community'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showMemberManagement() {
    final userViewModel = context.read<UserViewModel>();
    final communityViewModel = context.read<CommunityViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Community Members',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _community.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = _community.memberIds[index];
                  final user = userViewModel.users.firstWhere(
                        (u) => u.id == memberId,
                    orElse: () => User(
                      id: memberId,
                      username: 'Unknown',
                      email: 'unknown@example.com',
                      avatarUrl: '',
                    ),
                  );

                  final isAdmin = _community.adminIds.contains(memberId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAdmin ? Colors.orange : Colors.blue,
                        child: Text(user.username[0].toUpperCase()),
                      ),
                      title: Text(user.username),
                      subtitle: Text(isAdmin ? 'Admin' : 'Member'),
                      trailing: _isAdmin() && memberId != widget.currentUserId
                          ? PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            onTap: () async {
                              await communityViewModel.changeMemberRole(
                                _community.communityId,
                                memberId,
                                isAdmin ? 'member' : 'admin',
                              );
                              if (mounted) {
                                setState(() {
                                  if (isAdmin) {
                                    _community.adminIds.remove(memberId);
                                  } else {
                                    _community.adminIds.add(memberId);
                                  }
                                });
                              }
                            },
                            child: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                          ),
                          PopupMenuItem(
                            onTap: () async {
                              await communityViewModel.removeMember(
                                _community.communityId,
                                memberId,
                              );
                              if (mounted) {
                                setState(() {
                                  _community.memberIds.remove(memberId);
                                  _community.adminIds.remove(memberId);
                                });
                              }
                            },
                            child: const Text(
                              'Remove Member',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _community.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Community'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<CommunityViewModel>().renameCommunity(
                  _community.communityId,
                  controller.text,
                );
                if (mounted) {
                  setState(() {
                    _community = _community.copyWith(name: controller.text);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Community renamed!')),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CommunityPostViewModel>();
    final userViewModel = context.watch<UserViewModel>();
    final posts = viewModel.posts;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _community.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.groups,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (_isAdmin())
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showRenameDialog,
                  tooltip: 'Rename',
                ),
              if (_isAdmin())
                IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: _showMemberManagement,
                  tooltip: 'Manage Members',
                ),
              if (_isMember())
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: _leaveCommunity,
                  tooltip: 'Leave',
                ),
            ],
          ),

          // Community Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_community.description != null && _community.description!.isNotEmpty)
                        Text(
                          _community.description!,
                          style: TextStyle(color: Colors.grey[700], fontSize: 15),
                        )
                      else
                        Text(
                          'A place where members can share updates & discuss favorite shows',
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.people, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '${_community.memberIds.length} members',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_isAdmin()) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Post Input Section (if member)
          if (_isMember())
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share an update',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _postController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'What\'s on your mind? Share your favorite shows...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _publishPost,
                            icon: const Icon(Icons.send),
                            label: const Text('Post'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Posts Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Community Posts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Posts List
          posts.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share something!',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final post = posts[index];
                final author = userViewModel.users.firstWhere(
                      (u) => u.id == post.authorId,
                  orElse: () => User(
                    id: post.authorId,
                    username: 'Unknown User',
                    email: 'unknown@example.com',
                    avatarUrl: '',
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  author.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      author.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(post.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (post.authorId == widget.currentUserId)
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: () async {
                                        await context
                                            .read<CommunityPostViewModel>()
                                            .deletePost(post.postId);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Post deleted')),
                                          );
                                        }
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.content,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<CommunityPostViewModel>().likePost(
                                    post.postId,
                                    widget.currentUserId,
                                  );
                                },
                                icon: Icon(
                                  post.likes.contains(widget.currentUserId)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                ),
                                label: Text('${post.likes.length}'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  backgroundColor: post.likes.contains(widget.currentUserId)
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey[200],
                                  foregroundColor: post.likes.contains(widget.currentUserId)
                                      ? Colors.red
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}
