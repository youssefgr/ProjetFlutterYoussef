import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// 🌐 Manager centralisé pour Supabase + Google OAuth + Drive API
class SupabaseManager {
  static const String _supabaseUrl = 'https://dcpztcjhgbekbadfosvt.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjcHp0Y2poZ2Jla2JhZGZvc3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjczNzcsImV4cCI6MjA3NzAwMzM3N30.6SFr-6oB7e_4eGMGK5F74kZb42jXW52TRdz04NnOuls';

  /// ✅ Initialise Supabase une seule fois au lancement de l’app
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      debug: true,
    );
    debugPrint('🟢 Supabase initialisé avec succès');
  }

  /// Client global Supabase
  static SupabaseClient get client => Supabase.instance.client;

  /// 🔑 Connexion via Supabase Google OAuth (Android ou Web)
 
static Future<void> signInWithGoogle(BuildContext context) async {
  try {
    debugPrint('🚀 Tentative de connexion Google via Supabase...');

    // 🔑 Lancement OAuth officiel (plus besoin de url_launcher)
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
      scopes: 'email https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/drive.metadata.readonly',
    );

    // 🔍 Écoute du retour du deep link automatiquement
    client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('✅ Utilisateur connecté via Google : ${session.user?.email}');
        debugPrint('🔑 Provider token : ${session.providerToken}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Connexion Google réussie !')),
        );
      } else {
        debugPrint('⚠️ Aucun token Google détecté après callback.');
      }
    });
  } catch (e, st) {
    debugPrint('🔥 Erreur OAuth Google : $e');
    debugPrint(st.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur OAuth Google : $e')),
    );
  }
}



  /// ☁️ Création du client authentifié Google Drive
  static Future<gauth.AuthClient?> getGoogleAuthClient() async {
    try {
      final session = client.auth.currentSession;

      if (session == null) {
        debugPrint('⚠️ Aucune session Supabase active.');
        return null;
      }

      final accessToken = session.providerToken;
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ Aucun token Google détecté dans la session Supabase.');
        return null;
      }

      debugPrint('🟢 Token Google récupéré : $accessToken');

      final credentials = gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [
          'https://www.googleapis.com/auth/drive.readonly',
          'https://www.googleapis.com/auth/drive.metadata.readonly',
        ],
      );

      debugPrint('✅ Client Google Auth initialisé avec succès.');
      return gauth.authenticatedClient(http.Client(), credentials);
    } catch (e, st) {
      debugPrint('❌ Erreur création AuthClient Google : $e');
      debugPrint('📜 Stacktrace : $st');
      return null;
    }
  }

  /// 🔒 Vérifie si un utilisateur est connecté à Supabase
  static bool get isLoggedIn => client.auth.currentUser != null;

  /// 🔚 Déconnexion propre
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
      debugPrint('👋 Déconnecté proprement de Supabase.');
    } catch (e, st) {
      debugPrint('⚠️ Erreur déconnexion : $e');
      debugPrint('📜 Stacktrace : $st');
    }
  }
}
