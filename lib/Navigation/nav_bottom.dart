import 'package:flutter/material.dart';

import 'package:projetflutteryoussef/Home/home.dart';
import 'package:projetflutteryoussef/Pages/expenses_page.dart';
import 'package:projetflutteryoussef/Pages/subscription_page.dart';
import 'package:projetflutteryoussef/Entities/Akram/media_entities.dart';


class NavBottom extends StatefulWidget {
  const NavBottom({super.key});

  @override
  State<NavBottom> createState() => _NavBottomState();
}

class _NavBottomState extends State<NavBottom> {
  int _currentIndex = 0;
  final List<Widget> _interfaces = const [Home(), Expenses(), Subscription_you()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("G-Store ESPRIT")),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text("G-Stoer ESPRIT"),
              automaticallyImplyLeading: false,
            ),
            ListTile(
              leading: const Icon(Icons.tab_rounded),
              title: const Text("Media Management"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/");
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
              leading: const Icon(Icons.tab_rounded),
              title: const Text("Navigation par tab"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/");
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monetization_on),
            label: "Expenses",
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.subscript),
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
