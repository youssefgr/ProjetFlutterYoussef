import 'package:flutter/material.dart';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'Views/Akram/media_google_connect.dart';
import 'Views/Youssef/Cart/cart_manager.dart';
import 'Views/Shared/Navigation/nav_bottom.dart';
import 'viewmodels/mediafile_viewmodel.dart';
import 'utils/supabase_manager.dart';
import 'viewmodels/shared_album_viewmodel.dart';
import 'viewmodels/maamoune/user_viewmodel.dart';
import 'viewmodels/maamoune/community_viewmodel.dart';
import 'viewmodels/maamoune/friendship_viewmodel.dart';
import 'services/maamoune/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Charger les variables d'environnement EN PREMIER
  await dotenv.load(fileName: ".env");

  // 2. Initialiser SupabaseManager
  await SupabaseManager.initialize();

  // 3. Initialiser Supabase
  await Supabase.initialize(
    url: "https://dcpztcjhgbekbadfosvt.supabase.co",
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjcHp0Y2poZ2Jla2JhZGZvc3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjczNzcsImV4cCI6MjA3NzAwMzM3N30.6SFr-6oB7e_4eGMGK5F74kZb42jXW52TRdz04NnOuls',
  );

  // 4. Initialiser les notifications
  await NotificationService.initialize();
  NotificationService.startPeriodicRecommendations();

  // 5. Configurer reCAPTCHA
  RecaptchaHandler.instance.setupSiteKey(dataSiteKey: "6LfRUfwrAAAAANDXqp1T1YAN8UrwVggR9fcPeTWB");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartManager()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => CommunityViewModel()),
        ChangeNotifierProvider(create: (_) => FriendshipViewModel()),
        ChangeNotifierProvider(create: (_) => MediaFileViewModel()),
        ChangeNotifierProvider(create: (_) => SharedAlbumViewModel()),
      ],
      child: const MyApp(),
    ),
  );
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