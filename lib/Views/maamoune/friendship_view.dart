import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../Models/maamoune/friendship.dart';
import '../../Models/maamoune/user.dart';
import '../../viewmodels/maamoune/friendship_viewmodel.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';

class FriendshipScreen extends StatefulWidget {
  const FriendshipScreen({super.key});

  @override
  State<FriendshipScreen> createState() => _FriendshipScreenState();
}

class _FriendshipScreenState extends State<FriendshipScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    currentUserId = Supabase.instance.client.auth.currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view friendships'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      await context.read<FriendshipViewModel>().fetchFriendships();
      await context.read<UserViewModel>().fetchUsers();
    }
  }

  List<Friendship> _getFriends(List<Friendship> allFriendships) {
    return allFriendships
        .where((f) =>
    (f.userId == currentUserId || f.friendId == currentUserId) &&
        f.status == FriendshipStatus.accepted)
        .toList();
  }

  List<Friendship> _getPendingRequests(List<Friendship> allFriendships) {
    return allFriendships
        .where((f) => f.friendId == currentUserId && f.status == FriendshipStatus.pending)
        .toList();
  }

  List<Friendship> _getSentRequests(List<Friendship> allFriendships) {
    return allFriendships
        .where((f) => f.userId == currentUserId && f.status == FriendshipStatus.pending)
        .toList();
  }

  User? _getUserFromId(String userId, List<User> users) {
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
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
                      child: const Icon(Icons.group, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Friends",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Manage your connections",
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
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Friends'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Sent'),
                ],
              ),
              Expanded(
                child: Consumer2<FriendshipViewModel, UserViewModel>(
                  builder: (context, friendshipViewModel, userViewModel, _) {
                    if (friendshipViewModel.isLoading || userViewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allFriendships = friendshipViewModel.friendships;
                    final allUsers = userViewModel.users;
                    final friends = _getFriends(allFriendships);
                    final pending = _getPendingRequests(allFriendships);
                    final sent = _getSentRequests(allFriendships);

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Friends tab
                        friends.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No friends yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            final friendship = friends[index];
                            final friendId = friendship.userId == currentUserId
                                ? friendship.friendId
                                : friendship.userId;
                            final friend = _getUserFromId(friendId, allUsers);

                            if (friend == null) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  backgroundImage: friend.avatarUrl.isNotEmpty
                                      ? NetworkImage(friend.avatarUrl)
                                      : null,
                                  child: friend.avatarUrl.isEmpty
                                      ? Text(
                                    friend.username[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null,
                                ),
                                title: Text(
                                  friend.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(friend.email),
                                trailing: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        title: const Text('Unfriend'),
                                        content: Text(
                                          'Are you sure you want to unfriend ${friend.username}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () async {
                                              await friendshipViewModel
                                                  .deleteFriendship(
                                                friendship.friendshipId,
                                              );
                                              if (mounted) {
                                                await friendshipViewModel
                                                    .fetchFriendships();
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Unfriended ${friend.username}',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            child:
                                            const Text('Unfriend'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.person_remove,
                                      size: 18),
                                  label: const Text('Unfriend'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Pending requests tab
                        pending.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mail_outline,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No pending requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: pending.length,
                          itemBuilder: (context, index) {
                            final friendship = pending[index];
                            final requester = _getUserFromId(friendship.userId, allUsers);

                            if (requester == null) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.orange,
                                  backgroundImage:
                                  requester.avatarUrl.isNotEmpty
                                      ? NetworkImage(
                                      requester.avatarUrl)
                                      : null,
                                  child: requester.avatarUrl.isEmpty
                                      ? Text(
                                    requester.username[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null,
                                ),
                                title: Text(
                                  requester.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(requester.email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await friendshipViewModel
                                            .acceptFriendRequest(
                                          friendship.friendshipId,
                                        );
                                        if (mounted) {
                                          await friendshipViewModel
                                              .fetchFriendships();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Now friends with ${requester.username}! ✅',
                                              ),
                                              backgroundColor:
                                              Colors.green,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.check,
                                          size: 18),
                                      label: const Text('Accept'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await friendshipViewModel
                                            .declineFriendRequest(
                                          friendship.friendshipId,
                                        );
                                        if (mounted) {
                                          await friendshipViewModel
                                              .fetchFriendships();
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Declined ${requester.username}',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.close,
                                          size: 18),
                                      label: const Text('Decline'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Sent requests tab
                        sent.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No sent requests',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: sent.length,
                          itemBuilder: (context, index) {
                            final friendship = sent[index];
                            final recipient = _getUserFromId(friendship.friendId, allUsers);

                            if (recipient == null) {
                              return const SizedBox.shrink();
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.blue,
                                  backgroundImage:
                                  recipient.avatarUrl.isNotEmpty
                                      ? NetworkImage(
                                      recipient.avatarUrl)
                                      : null,
                                  child: recipient.avatarUrl.isEmpty
                                      ? Text(
                                    recipient.username[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null,
                                ),
                                title: Text(
                                  recipient.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(recipient.email),
                                trailing: ElevatedButton.icon(
                                  onPressed: () async {
                                    await friendshipViewModel
                                        .deleteFriendship(
                                      friendship.friendshipId,
                                    );
                                    if (mounted) {
                                      await friendshipViewModel
                                          .fetchFriendships();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cancelled request to ${recipient.username}',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
    _tabController.dispose();
    super.dispose();
  }
}
