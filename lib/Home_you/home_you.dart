import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class Home_you extends StatefulWidget {
  const Home_you({super.key});

  @override
  State<Home_you> createState() => _Home_youState();
}

class _Home_youState extends State<Home_you> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("G-Store ESPRIT"),

      ),
    );
  }
}
