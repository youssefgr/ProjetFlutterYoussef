import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Navigation/nav_bottom.dart';
import 'package:projetflutteryoussef/Pages/expenses_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Workshops 5GamiX",
      routes: {
        "/": (context) => const NavBottom(),
        "/navBottom": (context) => const NavBottom(),
      },
    );
  }
}

