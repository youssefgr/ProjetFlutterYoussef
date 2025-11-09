import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:projetflutteryoussef/Views/Shared/Navigation/nav_bottom.dart';
import 'services/notifcation_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Media Manager App",
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (context) => const NavBottom(),
        "/navBottom": (context) => const NavBottom(),
      },
    );
  }
}
