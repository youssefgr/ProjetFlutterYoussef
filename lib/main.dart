import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:projetflutteryoussef/Views/Shared/Navigation/nav_bottom.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Views/Akram/media_google_connect.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.black,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.white,
          textColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        "/navBottom": (context) => const NavBottom(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _userLoggedOut = false;

  @override
  void initState() {
    super.initState();
    // Sign out on app start to prevent auto-login
    _signOutOnStart();
  }

  Future<void> _signOutOnStart() async {
    try {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
      setState(() => _userLoggedOut = true);
    } catch (e) {
      print('Signout error: $e');
      setState(() => _userLoggedOut = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_userLoggedOut) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const NavBottom();
          }
        }
        return const MediaGoogleConnect();
      },
    );
  }
}