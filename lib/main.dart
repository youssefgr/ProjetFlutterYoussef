import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:projetflutteryoussef/Views/Shared/Navigation/nav_bottom.dart';
import 'package:projetflutteryoussef/viewmodels/mediafile_viewmodel.dart';
import 'utils/supabase_manager.dart';
import 'package:projetflutteryoussef/viewmodels/shared_album_viewmodel.dart';

Future<void> main() async {
  // Initialisation Supabase avant le lancement de l'app
  await SupabaseManager.initialize();
    await dotenv.load(fileName: ".env"); // Charge les variables

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaFileViewModel()),
        ChangeNotifierProvider(create: (_) => SharedAlbumViewModel()),

      ],
      child: MaterialApp(
        title: "Media Manager App",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          "/": (context) => const NavBottom(),
          "/navBottom": (context) => const NavBottom(),
        },
      ),
    );
  }
}
