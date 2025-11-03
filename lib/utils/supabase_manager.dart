import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;

/// 🌐 Gestionnaire global Supabase + OAuth Google
/// -------------------------------------------------------------
/// Gère :
///   - l’initialisation de Supabase
///   - l’authentification Google (OAuth)
///   - le rafraîchissement automatique du JWT
///   - la création du client Google Drive
/// -------------------------------------------------------------
class SupabaseManager {
  static const String _supabaseUrl = 'https://dcpztcjhgbekbadfosvt.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjcHp0Y2poZ2Jla2JhZGZvc3Z0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MjczNzcsImV4cCI6MjA3NzAwMzM3N30.6SFr-6oB7e_4eGMGK5F74kZb42jXW52TRdz04NnOuls';
static final String hfApiKey = dotenv.env['HUGGINGFACE_TOKEN'] ?? '';

  // =============================================================
  // 🚀 INITIALISATION
  // =============================================================
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        detectSessionInUri: true,
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('🟢 Supabase initialisé avec succès');
  }

  /// Client Supabase global
  static SupabaseClient get client => Supabase.instance.client;

  /// ✅ Vérifie si un utilisateur est connecté
  static bool get isLoggedIn => client.auth.currentSession != null;

  // =============================================================
  // 🔑 CONNEXION GOOGLE (manuel)
  // =============================================================
  static Future<void> signInWithGoogle(BuildContext context) async {
  try {
    debugPrint('🚀 Connexion Google via Supabase...');

    // ✅ Purge toute session précédente (locale + serveur)
    await client.auth.signOut(scope: SignOutScope.global);

    // ✅ Déclenche l’authentification Google via Supabase
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback', // 🔁 retour automatique
     scopes: 'email profile openid https://www.googleapis.com/auth/drive.readonly https://www.googleapis.com/auth/drive.metadata.readonly',

      queryParams: {
        'prompt': 'consent', // force la sélection de compte Google
        'access_type': 'offline', // permet d’obtenir un refresh_token
      },
    );

    debugPrint('✅ Lancement du flux OAuth Google (attente retour Chrome)...');

  } catch (e, st) {
    debugPrint('🔥 Erreur OAuth Google : $e');
    debugPrint(st.toString());

    // ✅ Message utilisateur si contexte encore monté
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Erreur lors de la connexion Google : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

  static Future<bool> ensureGoogleTokenValid(BuildContext context) async {
  await ensureSessionFresh();

  final session = client.auth.currentSession;
  final token = session?.providerToken;
  final expiresAt = session?.expiresAt;

  if (token == null || token.isEmpty) {
    debugPrint("❌ Aucun token Google présent.");
    return false;
  }

  // Supabase ne rafraîchit pas automatiquement le providerToken
  // donc on vérifie l’expiration
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  if (expiresAt != null && expiresAt - now < 60) {
    debugPrint("🔁 Token Google expiré — nouvelle authentification requise.");
    await signInWithGoogle(context);
    return false;
  }

  debugPrint("✅ Token Google valide (${token.substring(0, 10)}...)");
  return true;
}


  // =============================================================
  // 🕒 RAFRAÎCHISSEMENT DU JWT
  // =============================================================
  static Future<void> ensureSessionFresh() async {
    try {
      final session = client.auth.currentSession;
      if (session == null) return;

      final expiresAt = session.expiresAt;
      if (expiresAt == null) return;

      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final remaining = expiresAt - now;

      if (remaining <= 60) {
        debugPrint('🔁 Rafraîchissement du JWT Supabase (expire dans ${remaining}s)');
        await client.auth.refreshSession();
        debugPrint('✅ JWT Supabase rafraîchi');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du rafraîchissement du JWT : $e');
    }
  }

  // =============================================================
  // ☁️ CLIENT GOOGLE DRIVE
  // =============================================================
  static Future<gauth.AuthClient?> getGoogleAuthClient() async {
    try {
      await ensureSessionFresh();
      final session = client.auth.currentSession;
      if (session == null) {
        debugPrint('⚠️ Aucune session Supabase active.');
        return null;
      }

      final token = session.providerToken;
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ Token Google expiré ou manquant — reconnecte-toi.');
        return null;
      }

      final credentials = gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          token,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [
          'https://www.googleapis.com/auth/drive.readonly',
          'https://www.googleapis.com/auth/drive.metadata.readonly',
        ],
      );

      debugPrint('✅ Client Google Auth initialisé.');
      return gauth.authenticatedClient(http.Client(), credentials);
    } catch (e, st) {
      debugPrint('❌ Erreur création client Google : $e');
      debugPrint(st.toString());
      return null;
    }
  }

  // =============================================================
  // 🔒 DÉCONNEXION
  // =============================================================
  static Future<void> signOut() async {
    try {
      await client.auth.signOut(scope: SignOutScope.global);
      debugPrint('👋 Déconnexion réussie.');
    } catch (e) {
      debugPrint('⚠️ Erreur déconnexion : $e');
    }
  }

  // =============================================================
  // 🧠 EXÉCUTION AVEC JWT À JOUR
  // =============================================================
  static Future<T> runWithFreshJwt<T>(Future<T> Function() action) async {
    try {
      await ensureSessionFresh();
      return await action();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST303' || e.message.contains('JWT expired')) {
        debugPrint('⚠️ JWT expiré — rafraîchissement automatique.');
        await client.auth.refreshSession();
        return await action();
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Erreur runWithFreshJwt : $e');
      rethrow;
    }
  }

  // =============================================================
  // 🧾 DEBUG SESSION (pour les tests)
  // =============================================================
  static Future<void> debugSessionState() async {
    final session = client.auth.currentSession;
    if (session == null) {
      debugPrint("❌ [DEBUG] Aucune session active !");
      return;
    }
    debugPrint("🧠 [DEBUG] Session actuelle :");
    debugPrint("   user_id        = ${session.user?.id}");
    debugPrint("   email          = ${session.user?.email}");
    debugPrint("   expiresAt (JWT)= ${session.expiresAt}");
    debugPrint("   provider_token = ${session.providerToken?.substring(0, 25)}...");
  }
}
