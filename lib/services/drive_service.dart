import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as gdrive;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as gauth;
import 'package:flutter/foundation.dart';
import '../utils/supabase_manager.dart';

const _scopes = <String>[gdrive.DriveApi.driveReadonlyScope];

class DriveService {
  /// 🔐 Utilise le token Google fourni par Supabase Auth
  Future<gdrive.DriveApi> _api() async {
    final session = SupabaseManager.client.auth.currentSession;
    final token = session?.providerToken;

    if (token == null || token.isEmpty) {
      throw Exception('❌ Aucun token Google valide — reconnecte-toi.');
    }

    debugPrint("🔑 Utilisation du token Google Supabase (Drive API)");

    // ✅ Date d’expiration correcte : UTC obligatoire
    final utcExpiry = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 1)); // conversion explicite UTC

    final credentials = gauth.AccessCredentials(
      gauth.AccessToken('Bearer', token, utcExpiry),
      null,
      _scopes,
    );

    final client = gauth.authenticatedClient(http.Client(), credentials);
    return gdrive.DriveApi(client);
  }

  /// 📁 Liste les fichiers images du Drive
  Future<List<gdrive.File>> listImages({int pageSize = 50}) async {
    try {
      final api = await _api();
      final res = await api.files.list(
        q: "mimeType contains 'image/' and trashed=false",
        pageSize: pageSize,
        $fields: 'files(id,name,mimeType,thumbnailLink,size)',
      );
      return res.files ?? <gdrive.File>[];
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des fichiers Drive : $e');
      return [];
    }
  }

  /// ☁️ Télécharge un fichier Drive en bytes
  Future<Uint8List> downloadFileBytes(String fileId) async {
    try {
      final api = await _api();
      final response = await api.files.get(
        fileId,
        downloadOptions: gdrive.DownloadOptions.fullMedia,
      );

      if (response is! gdrive.Media) {
        debugPrint("⚠️ Pas de contenu média pour le fichier $fileId");
        return Uint8List(0);
      }

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final data = Uint8List.fromList(bytes);
      debugPrint("📦 Fichier Drive téléchargé (${data.lengthInBytes} octets)");
      return data;
    } catch (e) {
      debugPrint("❌ Erreur Drive download ($fileId) : $e");
      return Uint8List(0);
    }
  }
}
