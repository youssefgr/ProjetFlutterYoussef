import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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
  String? currentUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    currentUserId = Supabase.instance.client.auth.currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (mounted) {
      await context.read<UserViewModel>().fetchUsers();
      await context.read<FriendshipViewModel>().fetchFriendships();
    }
  }

  void _sendFriendRequest(User user) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send friend requests'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final friendshipViewModel = context.read<FriendshipViewModel>();
    final newFriendship = Friendship(
      friendshipId: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId!,
      friendId: user.id,
      status: FriendshipStatus.pending,
    );

    await friendshipViewModel.sendFriendRequest(newFriendship);

    // Refresh friendships to update UI
    if (mounted) {
      await context.read<FriendshipViewModel>().fetchFriendships();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${user.username}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
            onPressed: () async {
              await context.read<FriendshipViewModel>().deleteFriendship(friendshipId);

              // Refresh friendships to update UI
              if (mounted) {
                await context.read<FriendshipViewModel>().fetchFriendships();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unfriended ${user.username}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(User user, List<Friendship> allFriendships) {
    if (currentUserId == null) {
      return const Chip(
        label: Text('Login Required', style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.grey,
      );
    }

    if (user.id == currentUserId) {
      return const Chip(
        label: Text('You', style: TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: Colors.blue,
      );
    }

    Friendship? friendship;
    for (var f in allFriendships) {
      if ((f.userId == currentUserId && f.friendId == user.id) ||
          (f.userId == user.id && f.friendId == currentUserId)) {
        friendship = f;
        break;
      }
    }

    if (friendship == null) {
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
        // I sent the request
        return Chip(
          label: const Text('Request Sent', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange,
          onDeleted: () {
            // Allow cancelling sent request
            context.read<FriendshipViewModel>().deleteFriendship(friendship!.friendshipId);
            context.read<FriendshipViewModel>().fetchFriendships();
          },
        );
      } else {
        // They sent me a request
        return const Chip(
          label: Text('Pending', style: TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange,
        );
      }
    }

    if (friendship.status == FriendshipStatus.accepted) {
      return ElevatedButton.icon(
        onPressed: () => _unfriend(user, friendship!.friendshipId),
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

  List<User> _getFilteredUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((user) {
      return user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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
                child: Column(
                  children: [
                    Row(
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer2<UserViewModel, FriendshipViewModel>(
                  builder: (context, userViewModel, friendshipViewModel, child) {
                    if (userViewModel.isLoading || friendshipViewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (userViewModel.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${userViewModel.error}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _initializeData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final allUsers = userViewModel.users;
                    final allFriendships = friendshipViewModel.friendships;
                    final filteredUsers = _getFilteredUsers(allUsers);

                    if (allUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 80, color: Colors.grey[300]),
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
                              'Users will appear here',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    }

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
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
                              backgroundColor: user.id == currentUserId
                                  ? Colors.blue
                                  : Theme.of(context).primaryColor,
                              backgroundImage: user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : null,
                              child: user.avatarUrl.isEmpty
                                  ? Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                                  : null,
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
                                      Expanded(
                                        child: Text(
                                          user.email,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: _buildActionButton(user, allFriendships),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
