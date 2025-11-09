import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/maamoune/user_view.dart';
import 'package:projetflutteryoussef/Views/maamoune/community_view.dart';
import 'package:projetflutteryoussef/Views/maamoune/friendship_view.dart';

class CommunityManagementScreen extends StatefulWidget {
  const CommunityManagementScreen({super.key});

  @override
  State<CommunityManagementScreen> createState() => _CommunityManagementScreenState();
}

class _CommunityManagementScreenState extends State<CommunityManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Users',
            ),
            Tab(
              icon: Icon(Icons.groups),
              text: 'Communities',
            ),
            Tab(
              icon: Icon(Icons.people_alt),
              text: 'Friendships',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UserScreen(),
          CommunityScreen(),
          FriendshipScreen(),
        ],
      ),
    );
  }
}
