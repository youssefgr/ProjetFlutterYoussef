import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as gdrive;

import '../../utils/supabase_manager.dart';

class DriveService {
  bool _isRefreshing = false;

  /// ✅ CORRIGÉ : Vérifie et rafraîchit le token sans vérifier le retour
  Future<bool> _ensureAuthenticated(BuildContext context) async {
    if (_isRefreshing) {
      debugPrint("🔄 Reconnexion déjà en cours...");
      return false;
    }

    try {
      _isRefreshing = true;

      // Vérifie d'abord si on a un token valide
      final isValid = await SupabaseManager.ensureGoogleTokenValid(context);
      if (!isValid) {
        debugPrint("🔁 Token expiré - tentative de reconnexion...");

        // ✅ CORRECTION : Appelle directement sans vérifier le retour
        await SupabaseManager.signInWithGoogle(context);

        // Vérifie si maintenant on a un token valide
        final newIsValid = await SupabaseManager.ensureGoogleTokenValid(context);
        if (!newIsValid) {
          throw Exception('GOOGLE_RELOGIN_REQUIRED');
        }
      }

      return true;
    } finally {
      _isRefreshing = false;
    }
  }

  /// ✅ API client avec gestion robuste des erreurs
  Future<gdrive.DriveApi> _api(BuildContext context) async {
    if (!await _ensureAuthenticated(context)) {
      throw Exception('GOOGLE_RELOGIN_REQUIRED');
    }

    final client = await SupabaseManager.getGoogleAuthClient();
    if (client == null) {
      debugPrint("❌ Aucun client Google après reconnexion");
      throw Exception('GOOGLE_RELOGIN_REQUIRED');
    }

    debugPrint("🟢 Client Google Drive initialisé");
    return gdrive.DriveApi(client);
  }

  /// ✅ Liste des images avec gestion d'erreur améliorée
  Future<List<gdrive.File>> listImages(BuildContext context, {int pageSize = 50}) async {
    try {
      final api = await _api(context);

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
      if (e.status == 401) {
        debugPrint('❌ Token expiré (401) - reconnexion requise');
        throw Exception('GOOGLE_RELOGIN_REQUIRED');
      }
      debugPrint('❌ Erreur API Drive (${e.status}): ${e.message}');
      rethrow;
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        rethrow; // Propager l'erreur de reconnexion
      }
      debugPrint('❌ Erreur listImages: $e');
      rethrow;
    }
  }

  /// ⬇️ Télécharge le contenu binaire d'un fichier Drive
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

  /// 🧾 Récupère les métadonnées d'un fichier Drive
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