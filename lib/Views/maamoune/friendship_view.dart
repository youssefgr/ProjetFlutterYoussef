import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/maamoune/friendship.dart';
import '../../Models/maamoune/user.dart';
import '../../viewmodels/maamoune/friendship_viewmodel.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';

class FriendshipScreen extends StatefulWidget {
  const FriendshipScreen({super.key});

  @override
  State<FriendshipScreen> createState() => _FriendshipScreenState();
}

class _FriendshipScreenState extends State<FriendshipScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String currentUserId = 'current_user_123';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendshipViewModel>().fetchFriendships();
      context.read<UserViewModel>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  User? _getUserById(String userId, UserViewModel userViewModel) {
    return userViewModel.getUserById(userId);
  }

  void _acceptRequest(Friendship friendship) {
    context.read<FriendshipViewModel>().updateFriendshipStatus(
      friendship.friendshipId,
      FriendshipStatus.accepted,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend request accepted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectRequest(Friendship friendship) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Request'),
        content: const Text('Are you sure you want to reject this friend request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<FriendshipViewModel>().deleteFriendship(friendship.friendshipId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Friend request rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _unfriend(Friendship friendship, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unfriend'),
        content: Text('Are you sure you want to unfriend $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<FriendshipViewModel>().deleteFriendship(friendship.friendshipId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unfriended $username'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    return Consumer2<FriendshipViewModel, UserViewModel>(
      builder: (context, friendshipViewModel, userViewModel, child) {
        final pendingRequests = friendshipViewModel.getPendingRequests(currentUserId);

        if (pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            final friendship = pendingRequests[index];
            final sender = _getUserById(friendship.userId, userViewModel);

            if (sender == null) return const SizedBox.shrink();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange,
                      child: Text(
                        sender.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sender.username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(sender.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => _acceptRequest(friendship),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Accept', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed: () => _rejectRequest(friendship),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendsTab() {
    return Consumer2<FriendshipViewModel, UserViewModel>(
      builder: (context, friendshipViewModel, userViewModel, child) {
        final friends = friendshipViewModel.getAcceptedFriends(currentUserId);

        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendship = friends[index];
            final friendId = friendship.userId == currentUserId ? friendship.friendId : friendship.userId;
            final friend = _getUserById(friendId, userViewModel);

            if (friend == null) return const SizedBox.shrink();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.green,
                  child: Text(
                    friend.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                title: Text(
                  friend.username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(friend.email, style: const TextStyle(fontSize: 12)),
                    if (friend.communities.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.groups, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('${friend.communities.length} communities', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.red),
                  onPressed: () => _unfriend(friendship, friend.username),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequestsTab() {
    return Consumer2<FriendshipViewModel, UserViewModel>(
      builder: (context, friendshipViewModel, userViewModel, child) {
        final sentRequests = friendshipViewModel.getSentRequests(currentUserId);

        if (sentRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No sent requests',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sentRequests.length,
          itemBuilder: (context, index) {
            final friendship = sentRequests[index];
            final recipient = _getUserById(friendship.friendId, userViewModel);

            if (recipient == null) return const SizedBox.shrink();

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange,
                  child: Text(
                    recipient.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                title: Text(
                  recipient.username,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(recipient.email),
                trailing: const Chip(
                  label: Text('Pending', style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_alt, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Friendships",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Manage your connections",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(icon: Icon(Icons.inbox), text: 'Requests'),
                  Tab(icon: Icon(Icons.people), text: 'Friends'),
                  Tab(icon: Icon(Icons.send), text: 'Sent'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingRequestsTab(),
                    _buildFriendsTab(),
                    _buildSentRequestsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}