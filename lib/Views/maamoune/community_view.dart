import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/maamoune/community.dart';
import '../../Models/maamoune/user.dart';
import '../../viewmodels/maamoune/community_viewmodel.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';
import '../../viewmodels/maamoune/community_post_view_model.dart';
import '../../Models/maamoune/community_post.dart';
import '../../Views/maamoune/community_detail_view.dart';

enum CommunityFilter { all, myCommunities, joined, notJoined }
enum CommunitySortBy { name, memberCount, newest, oldest }

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final String currentUserId = 'current_user_123';

  late TabController _tabController;
  CommunityFilter _currentFilter = CommunityFilter.all;
  CommunitySortBy _currentSort = CommunitySortBy.newest;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityViewModel>().fetchCommunities();
      context.read<UserViewModel>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCommunityDialog() {
    _nameController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.group_add, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Create Community'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Community Name',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
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
              if (_nameController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
                final newCommunity = Community(
                  communityId: 'comm_${DateTime.now().millisecondsSinceEpoch}',
                  name: _nameController.text,
                  description: _descriptionController.text,
                  ownerId: currentUserId,
                  memberIds: [currentUserId],
                );
                context.read<CommunityViewModel>().createCommunity(newCommunity);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${newCommunity.name} created!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameCommunityDialog(Community community) {
    _nameController.text = community.name;
    _descriptionController.text = community.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename Community'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Community Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
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
              if (_nameController.text.isNotEmpty) {
                final updated = community.copyWith(
                  name: _nameController.text,
                  description: _descriptionController.text,
                );
                context.read<CommunityViewModel>().updateCommunity(updated);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Community updated!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Manage Members'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<UserViewModel>(
            builder: (context, userViewModel, child) {
              final members = community.memberIds
                  .map((id) => userViewModel.getUserById(id))
                  .where((user) => user != null)
                  .cast<User>()
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isOwner = community.isOwner(member.userId);
                  final isAdmin = community.isAdmin(member.userId);

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(member.username[0].toUpperCase()),
                    ),
                    title: Text(member.username),
                    subtitle: Text(
                      isOwner ? 'Owner' : isAdmin ? 'Admin' : 'Member',
                      style: TextStyle(
                        color: isOwner ? Colors.blue : isAdmin ? Colors.green : Colors.grey,
                      ),
                    ),
                    trailing: !isOwner && community.isOwner(currentUserId)
                        ? PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text(isAdmin ? 'Remove Admin' : 'Make Admin'),
                          onTap: () {
                            Future.delayed(Duration.zero, () {
                              if (isAdmin) {
                                context.read<CommunityViewModel>().demoteFromAdmin(
                                  community.communityId,
                                  member.userId,
                                );
                              } else {
                                context.read<CommunityViewModel>().promoteToAdmin(
                                  community.communityId,
                                  member.userId,
                                );
                              }
                            });
                          },
                        ),
                      ],
                    )
                        : null,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteCommunity(Community community) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Community'),
        content: Text('Are you sure you want to delete "${community.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<CommunityViewModel>().deleteCommunity(community.communityId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Community deleted'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Delete'),
          ),
        ],
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

  void _joinCommunity(Community community) {
    context.read<CommunityViewModel>().joinCommunity(community.communityId, currentUserId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined ${community.name}!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  List<Community> _getFilteredAndSortedCommunities(List<Community> communities) {
    // Apply filter
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

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply sort
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

  Widget _buildCommunityActions(Community community) {
    final isMember = community.isMember(currentUserId);
    final isOwner = community.isOwner(currentUserId);
    final isAdmin = community.isAdmin(currentUserId);

    if (!isMember) {
      return ElevatedButton.icon(
        onPressed: () => _joinCommunity(community),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Join'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        if (isAdmin) ...[
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
                  () => _showRenameCommunityDialog(community),
            ),
          ),
        ],
        if (isOwner) ...[
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.people, size: 18),
                SizedBox(width: 8),
                Text('Manage Members'),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
                  () => _showManageMembersDialog(community),
            ),
          ),
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
                  () => _deleteCommunity(community),
            ),
          ),
        ] else ...[
          PopupMenuItem(
            child: const Row(
              children: [
                Icon(Icons.exit_to_app, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text('Leave', style: TextStyle(color: Colors.orange)),
              ],
            ),
            onTap: () => Future.delayed(
              Duration.zero,
                  () => _leaveCommunity(community),
            ),
          ),
        ],
      ],
    );
  }

  String _getUserRole(Community community) {
    if (community.isOwner(currentUserId)) return 'Owner';
    if (community.isAdmin(currentUserId)) return 'Admin';
    if (community.isMember(currentUserId)) return 'Member';
    return '';
  }

  Color _getRoleColor(Community community) {
    if (community.isOwner(currentUserId)) return Colors.blue;
    if (community.isAdmin(currentUserId)) return Colors.green;
    if (community.isMember(currentUserId)) return Colors.orange;
    return Colors.grey;
  }

  Color _getRandomColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.teal];
    return colors[index % colors.length];
  }

  void _navigateToCommunityDetail(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CommunityPostViewModel(),
          child: CommunityDetailScreen(
            community: community,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }

  Widget _buildAllCommunitiesTab() {
    return Consumer<CommunityViewModel>(
      builder: (context, viewModel, child) {
        final communities = _getFilteredAndSortedCommunities(viewModel.communities);

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
                const SizedBox(height: 8),
                Text('Create the first community', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }

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
                const SizedBox(height: 8),
                Text('Try adjusting filters or search', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            final color = _getRandomColor(index);
            final role = _getUserRole(community);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _navigateToCommunityDetail(community),
                borderRadius: BorderRadius.circular(16),
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
                            // Main content area - tappable
                            Expanded(
                              child: Row(
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
                                        if (role.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(community).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              role,
                                              style: TextStyle(
                                                color: _getRoleColor(community),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Actions area - not tappable for navigation
                            _buildCommunityActions(community),
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
                            const SizedBox(width: 16),
                            Icon(Icons.admin_panel_settings, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${community.adminIds.length + 1} admins',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyCommunitiesTab() {
    return Consumer<CommunityViewModel>(
      builder: (context, viewModel, child) {
        final myCommunities = viewModel.communities.where((c) => c.isMember(currentUserId)).toList();

        if (myCommunities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Not in any communities',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text('Join or create a community', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myCommunities.length,
          itemBuilder: (context, index) {
            final community = myCommunities[index];
            final color = _getRandomColor(index);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _navigateToCommunityDetail(community),
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups, color: Colors.white, size: 28),
                  ),
                  title: Text(
                    community.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRoleColor(community).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getUserRole(community),
                          style: TextStyle(
                            color: _getRoleColor(community),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: _buildCommunityActions(community),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PopupMenuButton<CommunityFilter>(
                            initialValue: _currentFilter,
                            onSelected: (filter) {
                              setState(() {
                                _currentFilter = filter;
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: CommunityFilter.all,
                                child: Text('All Communities'),
                              ),
                              const PopupMenuItem(
                                value: CommunityFilter.myCommunities,
                                child: Text('My Communities'),
                              ),
                              const PopupMenuItem(
                                value: CommunityFilter.joined,
                                child: Text('Joined'),
                              ),
                              const PopupMenuItem(
                                value: CommunityFilter.notJoined,
                                child: Text('Not Joined'),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.filter_list, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentFilter.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PopupMenuButton<CommunitySortBy>(
                            initialValue: _currentSort,
                            onSelected: (sort) {
                              setState(() {
                                _currentSort = sort;
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: CommunitySortBy.newest,
                                child: Text('Newest First'),
                              ),
                              const PopupMenuItem(
                                value: CommunitySortBy.oldest,
                                child: Text('Oldest First'),
                              ),
                              const PopupMenuItem(
                                value: CommunitySortBy.name,
                                child: Text('Name (A-Z)'),
                              ),
                              const PopupMenuItem(
                                value: CommunitySortBy.memberCount,
                                child: Text('Most Members'),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.sort, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentSort.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim(),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                          ),
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
                  Tab(text: 'All Communities'),
                  Tab(text: 'My Communities'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllCommunitiesTab(),
                    _buildMyCommunitiesTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCommunityDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Community'),
      ),
    );
  }
}