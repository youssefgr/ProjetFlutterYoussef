import 'package:flutter/material.dart';
import '../../Akram/Media/media_home.dart';
import '../../Akram/Media/media_list.dart';

class NavBottom extends StatefulWidget {
  const NavBottom({super.key});

  @override
  State<NavBottom> createState() => _NavBottomState();
}

class _NavBottomState extends State<NavBottom> {
  int _currentIndex = 0;
  final List<Widget> _interfaces = const [MediaHome(), MediaList()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Media Manager App"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text("MENU"),
              backgroundColor: Colors.black,
              automaticallyImplyLeading: false,
            ),
            _buildDrawerItem(Icons.home, "Media Home", 0),  // Points to MediaHome
            _buildDrawerItem(Icons.movie, "My Media", 1),   // Points to MediaList
            _buildDrawerItem(Icons.cloud, "Cloud Management", 0),
            _buildDrawerItem(Icons.attach_money, "Expenses Management", 0),
            _buildDrawerItem(Icons.people, "Community Management", 0),
            _buildDrawerItem(Icons.event, "Event Management", 0),
          ],
        ),
      ),
      body: _interfaces[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),      // MediaHome
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: "My Media"), // MediaList
        ],
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
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