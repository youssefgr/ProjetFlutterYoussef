import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Home/home.dart';
import 'package:projetflutteryoussef/Pages/expenses_page.dart';
import 'package:projetflutteryoussef/Pages/subscription_page.dart';
import 'package:projetflutteryoussef/Crud/Akram/media_list.dart';

class NavBottom extends StatefulWidget {
  const NavBottom({super.key});

  @override
  State<NavBottom> createState() => _NavBottomState();
}

class _NavBottomState extends State<NavBottom> {
  int _currentIndex = 0;
  final List<Widget> _interfaces = const [Home(), MediaList(), Expenses(), Subscription_you()];

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
              leading: const Icon(Icons.edit),
              title: const Text("Modifier le profil"),
              onTap: () {
                Navigator.pushNamed(context, "/home/editProfile");
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                setState(() {
                  _currentIndex = 0; // Home index
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Se déconnecter"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/");
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
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: "Media",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: "Expenses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscript),
            label: "Subscription",
          )
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}