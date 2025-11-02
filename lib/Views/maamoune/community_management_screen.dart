import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/maamoune/user_view.dart';
import 'package:projetflutteryoussef/Views/maamoune/community_view.dart';
import 'package:projetflutteryoussef/Views/maamoune/friendship_view.dart';

class CommunityManagementScreen extends StatelessWidget {
  const CommunityManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community Management'),
          bottom: const TabBar(
            tabs: [
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
        body: const TabBarView(
          children: [
            UserScreen(),
            CommunityScreen(),
            FriendshipScreen(),
          ],
        ),
      ),
    );
  }
}