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
  final String currentUserId = 'current_user_123';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().fetchUsers();
      context.read<FriendshipViewModel>().fetchFriendships();
    });
  }

  void _showAddUserDialog() {
    _usernameController.clear();
    _emailController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Add Test User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add users to test friend requests and communities',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_usernameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
                final newUser = User(
                  userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  username: _usernameController.text,
                  email: _emailController.text,
                  avatarUrl: 'https://ui-avatars.com/api/?name=${_usernameController.text}',
                );
                context.read<UserViewModel>().addUser(newUser);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${newUser.username} added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
                    final allUsers = userViewModel.users;
                    final filteredUsers = _getFilteredUsers(allUsers);

                    if (allUsers.isEmpty) {
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
                              'Add test users to get started',
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
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[300],
                            ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Test User'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}