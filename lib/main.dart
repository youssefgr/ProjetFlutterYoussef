import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Navigation_you/nav_bottom_you.dart';
import 'package:projetflutteryoussef/Pages_you/expenses_page_you.dart';

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
        "/": (context) => const NavBottom_you(),
        "/navBottom": (context) => const NavBottom_you(),
      },
    );
  }
}

