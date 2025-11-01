import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:projetflutteryoussef/Views/Shared/Navigation/nav_bottom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/utils/recaptcha_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RecaptchaHandler.instance.setupSiteKey(dataSiteKey: "6LfRUfwrAAAAANDXqp1T1YAN8UrwVggR9fcPeTWB");

  await Supabase.initialize(
    url: "https://dcpztcjhgbekbadfosvt.supabase.co",
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjcHp0Y2poZ2Jla2JhZGZvc3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjczNzcsImV4cCI6MjA3NzAwMzM3N30.6SFr-6oB7e_4eGMGK5F74kZb42jXW52TRdz04NnOuls',
  );
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

