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
      title: "Media Manager App",
      routes: {
        "/": (context) => const NavBottom(),
        "/navBottom": (context) => const NavBottom(),
      },
    );
  }
}

