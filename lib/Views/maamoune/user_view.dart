import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/maamoune/user.dart';
import '../../Models/maamoune/friendship.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';
import '../../viewmodels/maamoune/friendship_viewmodel.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // Simulated current logged-in user ID (in real app, this comes from auth)
  final String currentUserId = 'current_user_123';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().fetchUsers();
      context.read<FriendshipViewModel>().fetchFriendships();
    });
  }

  void _sendFriendRequest(User user) {
    final friendshipViewModel = context.read<FriendshipViewModel>();

    final newFriendship = Friendship(
      friendshipId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId,
      friendId: user.userId,
      status: FriendshipStatus.pending,
    );

    friendshipViewModel.sendFriendRequest(newFriendship);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to ${user.username}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _unfriend(User user, String friendshipId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unfriend'),
        content: Text('Are you sure you want to unfriend ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<FriendshipViewModel>().deleteFriendship(friendshipId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unfriended ${user.username}'),
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

  Widget _buildActionButton(User user, FriendshipViewModel friendshipViewModel) {
    if (user.userId == currentUserId) {
      return Chip(
        label: const Text('You', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      );
    }

    final friendship = friendshipViewModel.getFriendshipBetween(currentUserId, user.userId);

    if (friendship == null) {
      // Not friends, show Add Friend button
      return ElevatedButton.icon(
        onPressed: () => _sendFriendRequest(user),
        icon: const Icon(Icons.person_add, size: 18),
        label: const Text('Add Friend'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    if (friendship.status == FriendshipStatus.pending) {
      if (friendship.userId == currentUserId) {
        return const Chip(
          label: Text('Request Sent', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange,
        );
      } else {
        return const Chip(
          label: Text('Pending', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange,
        );
      }
    }

    if (friendship.status == FriendshipStatus.accepted) {
      return ElevatedButton.icon(
        onPressed: () => _unfriend(user, friendship.friendshipId),
        icon: const Icon(Icons.person_remove, size: 18),
        label: const Text('Unfriend'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      );
    }

    if (friendship.status == FriendshipStatus.blocked) {
      return const Chip(
        label: Text('Blocked', style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.red,
      );
    }

    return const SizedBox.shrink();
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
                      child: const Icon(Icons.people, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All Users",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Connect with other users",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer2<UserViewModel, FriendshipViewModel>(
                  builder: (context, userViewModel, friendshipViewModel, child) {
                    if (userViewModel.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users yet',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Users will appear here when they sign up',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: userViewModel.users.length,
                      itemBuilder: (context, index) {
                        final user = userViewModel.users[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: user.userId == currentUserId
                                  ? Colors.blue
                                  : Theme.of(context).primaryColor,
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(user.email),
                                    ],
                                  ),
                                  if (user.communities.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.groups, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${user.communities.length} communities'),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            trailing: _buildActionButton(user, friendshipViewModel),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}