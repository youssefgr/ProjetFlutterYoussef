import 'package:flutter/material.dart';


import 'package:projetflutteryoussef/Home_you/home_you.dart';
import 'package:projetflutteryoussef/Pages_you/expenses_page_you.dart';
import 'package:projetflutteryoussef/Pages_you/subscription_page_you.dart';
import 'package:flutter/material.dart';


class NavBottom_you extends StatefulWidget {
  const NavBottom_you({super.key});

  @override
  State<NavBottom_you> createState() => _NavBottom_youState();
}

class _NavBottom_youState extends State<NavBottom_you> {
  int _currentIndex = 0;
  final List<Widget> _interfaces = const [Home_you(), Expenses_you(), Subscription_you()];

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
                Navigator.pushReplacementNamed(context, "/navTab");
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
