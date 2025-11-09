import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/Home/home.dart';
import 'package:projetflutteryoussef/Views/Akram/media_list.dart';
import 'package:projetflutteryoussef/Views/Yassine/event_list.dart';

class NavBottom extends StatefulWidget {
  const NavBottom({super.key});

  @override
  State<NavBottom> createState() => _NavBottomState();
}

class _NavBottomState extends State<NavBottom> {
  int _currentIndex = 0;
  final List<Widget> _interfaces = const [Home(), MediaList(),EventListScreen(),];

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
              leading: const Icon(Icons.movie),
              title: const Text("Media Management"),
              onTap: () {
                setState(() {
                  _currentIndex = 1; // MediaList index
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text("Cloud Management"),
              onTap: () {
                setState(() {
                  _currentIndex = 0; // MediaList index
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text("Expenses Management"),
              onTap: () {
                setState(() {
                  _currentIndex = 0; // MediaList index
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: const Text("Community Management"),
              onTap: () {
                setState(() {
                  _currentIndex = 0; // MediaList index
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("Event Management"),
              onTap: () {
                setState(() {
                  _currentIndex = 2; // MediaList index

                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _interfaces[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          /*BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: "Edit Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Disconnect",
          ),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: "Media",
          )
          /*BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: "Expenses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscript),
            label: "Subscription",
          )*/
        ],
        currentIndex: _currentIndex > 1 ? 0 : _currentIndex,

        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}