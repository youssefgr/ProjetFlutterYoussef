import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Views/Shared/Navigation/nav_bottom.dart';
import 'package:projetflutteryoussef/viewmodels/maamoune/user_viewmodel.dart';
import 'package:projetflutteryoussef/viewmodels/maamoune/community_viewmodel.dart';
import 'package:projetflutteryoussef/viewmodels/maamoune/friendship_viewmodel.dart';
import 'package:provider/provider.dart';
import 'services/maamoune/notification_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  NotificationService.startPeriodicRecommendations();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => CommunityViewModel()),
        ChangeNotifierProvider(create: (_) => FriendshipViewModel()),
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
      routes: {
        "/": (context) => const NavBottom(),
        "/navBottom": (context) => const NavBottom(),
      },
    );
  }
}

