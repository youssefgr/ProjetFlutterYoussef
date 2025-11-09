import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Akram/Media/TopMediaPieChart.dart';
import '../../Akram/Media/media_home.dart';
import '../../Akram/Media/media_list.dart';
import '../../Youssef/Expenses Crud/expenses_list.dart';
import '../../Youssef/Subscriptions Crud/subscriptions_list.dart';
import 'package:projetflutteryoussef/Views/Hajer/mediafile_page.dart';
import 'package:projetflutteryoussef/Views/Hajer/shared_album_page.dart';
import 'package:projetflutteryoussef/Views/maamoune/community_management_screen.dart';

class NavBottom extends StatefulWidget {
  const NavBottom({super.key});

  @override
  State<NavBottom> createState() => _NavBottomState();
}

class _NavBottomState extends State<NavBottom> {
  int _currentIndex = 0;

  final List<Widget> _interfaces = [
    const MediaHome(), // Onglet 0 → Media Home (Akram)
    const MediaList(), // Onglet 1 → My Media (Akram)
    const ExpensesList(), // Onglet 2 → Expenses Management (Youssef)
    const SubscriptionsList(), // Onglet 3 → Subscriptions (Youssef)
    const CommunityManagementScreen(), // Onglet 4 → Community (Maamoune)
    const MediaFilePage(mediaItemId: "00000000-0000-0000-0000-000000000001"), // Onglet 5 → Cloud Manager (Hajer)
    const SharedAlbumPage(currentUserId: "00000000-0000-0000-0000-000000000001"), // Onglet 6 → Shared Album (Hajer)
  ];

  Future<void> _handleDisconnect() async {
    try {
      // Clear all sessions and tokens
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);

      if (mounted) {
        // Navigate back to login without keeping history
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDisconnectConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Are you sure you want to disconnect your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDisconnect();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Media Manager App"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            tooltip: 'Top Rated Media',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TopMediaPieChart()),
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: Column(
          children: [
            AppBar(
              title: const Text("MENU"),
              backgroundColor: Colors.black,
              automaticallyImplyLeading: false,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
            ),
            // ✅ Items du drawer avec navigation correcte
            _buildDrawerItem(Icons.home, "Media Home", 0),
            _buildDrawerItem(Icons.movie, "My Media", 1),
            _buildDrawerItem(Icons.attach_money, "Expenses Management", 2),
            _buildDrawerItem(Icons.task, "Subscriptions Management", 3),
            _buildDrawerItem(Icons.people, "Community Management", 4),
            _buildDrawerItem(Icons.cloud, "Cloud Management", 5),
            _buildDrawerItem(Icons.share, "Shared Albums", 6),

            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade700)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ??
                        Supabase.instance.client.auth.currentUser?.email?.split('@')[0] ??
                        'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Supabase.instance.client.auth.currentUser?.email ?? 'No email',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showDisconnectConfirm,
                      icon: const Icon(Icons.logout),
                      label: const Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _interfaces[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: "Media",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Expenses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: "Subscriptions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Community",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: "Cloud",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.share),
            label: "Shared",
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) => ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(title, style: const TextStyle(color: Colors.white)),
    onTap: () {
      setState(() => _currentIndex = index);
      Navigator.pop(context);
    },
  );
}