import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:projetflutteryoussef/Views/Shared/Navigation/nav_bottom.dart';
import 'package:projetflutteryoussef/viewmodels/maamoune/message_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'Views/Akram/media_google_connect.dart';
import 'Views/Youssef/Cart/cart_manager.dart';



import 'package:projetflutteryoussef/viewmodels/maamoune/user_viewmodel.dart';
import 'package:projetflutteryoussef/viewmodels/maamoune/community_viewmodel.dart';
import 'package:projetflutteryoussef/viewmodels/maamoune/friendship_viewmodel.dart';
import 'services/maamoune/notification_service.dart';

import 'package:projetflutteryoussef/viewmodels/maamoune/community_post_view_model.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();
NotificationService.startPeriodicRecommendations();


  RecaptchaHandler.instance.setupSiteKey(dataSiteKey: "6LfRUfwrAAAAANDXqp1T1YAN8UrwVggR9fcPeTWB");

  await Supabase.initialize(
    url: "https://dcpztcjhgbekbadfosvt.supabase.co",
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjcHp0Y2poZ2Jla2JhZGZvc3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjczNzcsImV4cCI6MjA3NzAwMzM3N30.6SFr-6oB7e_4eGMGK5F74kZb42jXW52TRdz04NnOuls',
  );

  runApp(
  MultiProvider(
    providers: [
      //ChangeNotifierProvider(create: (_) => CartManager()),
      ChangeNotifierProvider(create: (_) => UserViewModel()),
      ChangeNotifierProvider(create: (_) => CommunityViewModel()),
      ChangeNotifierProvider(create: (_) => FriendshipViewModel()),
      ChangeNotifierProvider(create: (_) => CommunityPostViewModel()),
      ChangeNotifierProvider(create: (_) => MessageViewModel()),


    ],
    child: const MyApp(),
  ),
);

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartManager()),

        ],
        child: MaterialApp(
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
    ));
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _userLoggedOut = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _syncUserIfLoggedIn() async {
    try {
      final supabase = Supabase.instance.client;
      final authUser = supabase.auth.currentUser;

      print('🔍 Checking if user is logged in...');
      if (authUser == null) {
        print('❌ No user logged in');
        return;
      }

      print('✅ User logged in: ${authUser.id}');

      // NOW we have context, sync the user
      if (mounted) {
        print('🔄 Calling syncGoogleUser()...');
        final userViewModel = context.read<UserViewModel>();
        final syncedUser = await userViewModel.syncGoogleUser();

        if (syncedUser != null) {
          print('✅✅✅ USER SYNCED SUCCESSFULLY: ${syncedUser.id}');
        } else {
          print('❌❌❌ FAILED TO SYNC USER');
        }
      }
    } catch (e) {
      print('❌ Error in _syncUserIfLoggedIn: $e');
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

          // When user logs in
          if (session != null) {
            print('🎉 Session detected: ${session.user.id}');

            // Sync user AFTER stream detects login
            if (!_isInitialized) {
              _isInitialized = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _syncUserIfLoggedIn();
              });
            }

            return const NavBottom();
          } else {
            // User logged out
            _isInitialized = false;
          }
        }
        print('🔐 No session, showing login screen');
        return const MediaGoogleConnect();
      },
    );
  }
}

