import 'package:flutter/material.dart';

class Expenses_you extends StatefulWidget {
  const Expenses_you({super.key});

  @override
  State<Expenses_you> createState() => _Expenses_youState();
}

class _Expenses_youState extends State<Expenses_you> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Expense Tracker'),
      ),
    );
  }
}