import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;

import '../utils/supabase_manager.dart';

/// 🚚 Service Google Drive
/// - Vérifie le token Google avant chaque requête.
/// - Si expiré : renvoie `GOOGLE_RELOGIN_REQUIRED` → l’UI déclenche la reconnexion manuelle.
class DriveService {
  /// Crée une instance authentifiée de l’API Google Drive
  Future<gdrive.DriveApi> _api(BuildContext context) async {
  // Vérifie si la session Google existe encore
  final valid = await SupabaseManager.ensureGoogleTokenValid(context);
  if (!valid) {
    debugPrint("🔁 Token Google expiré — tentative de reconnexion...");
    await SupabaseManager.signInWithGoogle(context); // ✅ on laisse Chrome s’ouvrir
  }

  // Récupère le client Google (refresh après reconnection)
  final client = await SupabaseManager.getGoogleAuthClient();

  if (client == null) {
    debugPrint("❌ Aucun client Google valide après reconnexion");
    await SupabaseManager.signInWithGoogle(context);
    throw Exception('GOOGLE_RELOGIN_REQUIRED');
  }

  debugPrint("🟢 Client Google Drive initialisé avec succès !");
  return gdrive.DriveApi(client);
}


 Future<List<gdrive.File>> listImages(BuildContext context, {int pageSize = 50}) async {
  try {
    // ✅ Tente d'initialiser le client Drive
    final api = await _api(context);

    // ✅ Liste les fichiers image récents (non supprimés)
    final res = await api.files.list(
      q: "mimeType contains 'image/' and trashed = false",
      pageSize: pageSize,
      orderBy: 'modifiedTime desc',
      $fields: 'files(id,name,mimeType,thumbnailLink,iconLink,size,modifiedTime)',
    );

    final count = res.files?.length ?? 0;
    debugPrint('📂 Drive: $count fichier(s) image(s) trouvé(s).');
    return res.files ?? <gdrive.File>[];

  } on gdrive.DetailedApiRequestError catch (e) {
    // ⚠️ Token Google expiré → reconnexion manuelle demandée
    if (e.status == 401) {
      debugPrint('❌ Drive 401 (listImages): ${e.message}');
      await SupabaseManager.signInWithGoogle(context); // 🔁 relance le flux OAuth
      throw Exception('GOOGLE_RELOGIN_REQUIRED: ${e.message}');
    }

    debugPrint('❌ Erreur API Drive (${e.status}): ${e.message}');
    rethrow;

  } catch (e) {
    // ⚠️ Cas généraux : absence de client, coupure Internet, etc.
    if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
      debugPrint('🔑 Token Google expiré — reconnexion utilisateur requise.');
      await SupabaseManager.signInWithGoogle(context);
      throw Exception('GOOGLE_RELOGIN_REQUIRED');
    }

    debugPrint('❌ Erreur listImages: $e');
    rethrow;
  }
}


  /// ⬇️ Télécharge le contenu binaire d’un fichier Drive par son ID
  Future<Uint8List> downloadFileBytes(BuildContext context, String fileId) async {
    try {
      final api = await _api(context);
      final response = await api.files.get(
        fileId,
        downloadOptions: gdrive.DownloadOptions.fullMedia,
      );

      if (response is! gdrive.Media) {
        debugPrint('⚠️ Aucun contenu média trouvé pour $fileId');
        return Uint8List(0);
      }

      final chunks = <int>[];
      await for (final c in response.stream) {
        chunks.addAll(c);
      }

      final data = Uint8List.fromList(chunks);
      debugPrint('📦 Téléchargé ${data.lengthInBytes} octets depuis Drive ($fileId).');
      return data;
    } on gdrive.DetailedApiRequestError catch (e) {
      if (e.status == 401) {
        debugPrint('❌ Drive 401 (download): ${e.message}');
        throw Exception('GOOGLE_RELOGIN_REQUIRED: ${e.message}');
      }
      debugPrint('❌ Erreur Drive API (${e.status}) pendant le téléchargement: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Erreur downloadFileBytes($fileId): $e');
      rethrow;
    }
  }

  /// 🧾 Récupère les métadonnées d’un fichier Drive (nom, taille, type, etc.)
  Future<gdrive.File?> getFile(BuildContext context, String fileId) async {
    try {
      final api = await _api(context);
      final file = await api.files.get(
        fileId,
        $fields: 'id,name,mimeType,thumbnailLink,iconLink,size,modifiedTime',
      ) as gdrive.File;
      return file;
    } on gdrive.DetailedApiRequestError catch (e) {
      if (e.status == 401) {
        debugPrint('❌ Drive 401 (getFile): ${e.message}');
        throw Exception('GOOGLE_RELOGIN_REQUIRED: ${e.message}');
      }
      debugPrint('❌ Erreur récupération métadonnées: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Erreur getFile($fileId): $e');
      rethrow;
    }
  }
}
