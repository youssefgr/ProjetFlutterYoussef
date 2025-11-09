import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Models/maamoune/community.dart';
import '../../Models/maamoune/user.dart';
import '../../viewmodels/maamoune/community_viewmodel.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';

enum CommunityFilter { all, myCommunities, joined, notJoined }
enum CommunitySortBy { name, memberCount, newest, oldest }

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String currentUserId;

  CommunityFilter _currentFilter = CommunityFilter.all;
  CommunitySortBy _currentSort = CommunitySortBy.newest;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Get real user ID from Supabase Auth - with error handling
    try {
      currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'unknown_user';
    } catch (e) {
      currentUserId = 'unknown_user';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CommunityViewModel>().fetchCommunities();
        context.read<UserViewModel>().fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Community> _getFilteredAndSortedCommunities(List<Community> communities) {
    List<Community> filtered = communities;

    switch (_currentFilter) {
      case CommunityFilter.myCommunities:
        filtered = communities.where((c) => c.isOwner(currentUserId)).toList();
        break;
      case CommunityFilter.joined:
        filtered = communities.where((c) => c.isMember(currentUserId)).toList();
        break;
      case CommunityFilter.notJoined:
        filtered = communities.where((c) => !c.isMember(currentUserId)).toList();
        break;
      case CommunityFilter.all:
      default:
        filtered = communities;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    switch (_currentSort) {
      case CommunitySortBy.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CommunitySortBy.memberCount:
        filtered.sort((a, b) => b.memberIds.length.compareTo(a.memberIds.length));
        break;
      case CommunitySortBy.newest:
        filtered.sort((a, b) => b.communityId.compareTo(a.communityId));
        break;
      case CommunitySortBy.oldest:
        filtered.sort((a, b) => a.communityId.compareTo(b.communityId));
        break;
    }

    return filtered;
  }

  Color _getRandomColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.teal];
    return colors[index % colors.length];
  }

  void _joinCommunity(Community community) {
    context.read<CommunityViewModel>().joinCommunity(community.communityId, currentUserId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined ${community.name}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _leaveCommunity(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Community'),
        content: Text('Are you sure you want to leave "${community.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              context.read<CommunityViewModel>().leaveCommunity(community.communityId, currentUserId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Left community'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Community community, int index) {
    final color = _getRandomColor(index);
    final isMember = community.isMember(currentUserId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (isMember) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Member',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  isMember
                      ? PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Leave'),
                        onTap: () => Future.delayed(Duration.zero, () => _leaveCommunity(community)),
                      ),
                    ],
                  )
                      : ElevatedButton.icon(
                    onPressed: () => _joinCommunity(community),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                community.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${community.memberIds.length} members',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
                          child: const Icon(Icons.groups, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Communities",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Join and create communities",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search communities...',
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                child: Consumer<CommunityViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.communities.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No communities yet',
                              style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    final communities = _getFilteredAndSortedCommunities(viewModel.communities);

                    if (communities.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No communities found',
                              style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        return _buildCommunityCard(communities[index], index);
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
