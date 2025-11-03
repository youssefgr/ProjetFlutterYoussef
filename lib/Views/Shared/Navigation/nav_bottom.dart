import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/Home/home.dart';
import 'package:projetflutteryoussef/Views/Akram/media_list.dart';
import 'package:projetflutteryoussef/Views/Hajer/mediafile_page.dart';
import 'package:projetflutteryoussef/Views/Hajer/shared_album_page.dart';

class NavBottom extends StatefulWidget {
  const NavBottom({super.key});

  @override
  State<NavBottom> createState() => _NavBottomState();
}

class _NavBottomState extends State<NavBottom> {
  int _currentIndex = 0;

  final List<Widget> _interfaces = const [
    Home(),                       // Onglet 0 → accueil
    MediaList(),                  // Onglet 1 → Media Manager (Akram)
    MediaFilePage(mediaItemId: "00000000-0000-0000-0000-000000000001"), // Onglet 2 → Cloud Manager (Hajer)
    SharedAlbumPage(currentUserId: "00000000-0000-0000-0000-000000000001"), // Onglet 3 → Shared Album (Hajer)

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Media Manager App")),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text("MENU"),
              automaticallyImplyLeading: false,
            ),
            ListTile(
  leading: const Icon(Icons.share),
  title: const Text("Shared Albums"),
  onTap: () {
    setState(() => _currentIndex = 3);
    Navigator.pop(context);
  },
),

            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text("Media Management"),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text("Cloud Management"),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text("Expenses Management"),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Community Management"),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Event Management"),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _interfaces[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
  backgroundColor: Colors.white,
  selectedItemColor: Colors.deepPurple,
  unselectedItemColor: Colors.grey,
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
      icon: Icon(Icons.cloud),
      label: "Cloud",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: "Shared",
    ),
  ],
),

    );
  }
}
