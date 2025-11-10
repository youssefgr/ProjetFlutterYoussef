import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Models/Hajer/mediafile.dart';
import '../../services/Hajer/auto_tagging_service.dart';
import '../../services/Hajer/drive_service.dart';
import '../../utils/hash_utils.dart';
import '../../utils/supabase_manager.dart';


/// 🧩 Repository : couche métier pour gérer les fichiers média
class MediaFileRepository {
  final SupabaseClient _db = SupabaseManager.client;

  // =============================================================
  // 📥 READ : Récupération des fichiers liés à un MediaItem
  // =============================================================
  Future<List<MediaFile>> fetchByMediaItem(String mediaItemId) async {
    return await SupabaseManager.runWithFreshJwt(() async {
      final rows = await _db
          .from('mediafile')
          .select()
          .eq('mediaitemid', mediaItemId)
          .order('uploaddate', ascending: false);

      return (rows as List).map((e) => MediaFile.fromJson(e)).toList();
    });
  }

  // =============================================================
  // 📤 CREATE : depuis un fichier local
  // =============================================================
  Future<MediaFile> createFromLocalFile({
    required String mediaItemId,
    required String filePath,
    FileType type = FileType.poster,
    bool removeBackground = false,
  }) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final bytes = await File(filePath).readAsBytes();

    return await _createFromBytes(
      mediaItemId: mediaItemId,
      fileName: fileName,
      bytes: bytes,
      type: type,
      removeBackground: removeBackground,
    );
  }

  // =============================================================
  // ☁️ CREATE : depuis Google Drive
  // =============================================================
  Future<MediaFile> createFromGoogleDrive({
    required BuildContext context,
    required String mediaItemId,
    required String driveFileId,
    required String driveFileName,
    FileType type = FileType.poster,
    bool removeBackground = false,
  }) async {
    final drive = DriveService();
    debugPrint("☁️ Téléchargement depuis Drive : $driveFileName ($driveFileId)");

    Uint8List bytes;
    try {
      bytes = await drive.downloadFileBytes(context, driveFileId);
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        throw Exception("⚠️ Token Google expiré — reconnecte-toi manuellement.");
      }
      rethrow;
    }

    if (bytes.isEmpty) {
      throw Exception("❌ Fichier Drive vide ou inaccessible ($driveFileName)");
    }

    return await _createFromBytes(
      mediaItemId: mediaItemId,
      fileName: driveFileName,
      bytes: bytes,
      type: type,
      removeBackground: removeBackground,
    );
  }

  // =============================================================
  // 📥 CREATE : depuis bytes (pour Pinterest et autres)
  // =============================================================
  Future<MediaFile> createFromBytes({
    required String mediaItemId,
    required String fileName,
    required Uint8List bytes,
    FileType type = FileType.poster,
    bool removeBackground = false,
  }) async {
    return await _createFromBytes(
      mediaItemId: mediaItemId,
      fileName: fileName,
      bytes: bytes,
      type: type,
      removeBackground: removeBackground,
    );
  }

  // =============================================================
  // 🧱 CORE : Upload vers Supabase Storage + insertion en DB
  // =============================================================
  Future<MediaFile> _createFromBytes({
    required String mediaItemId,
    required String fileName,
    required Uint8List bytes,
    required FileType type,
    required bool removeBackground,
  }) async {
    return await SupabaseManager.runWithFreshJwt(() async {
      if (bytes.isEmpty) throw Exception("❌ Aucun contenu à uploader.");

      // 🔐 ID Media sécurisé
      var safeId = mediaItemId.trim();
      if (safeId.isEmpty || safeId == 'STATIC_MEDIAITEM_ID') {
        safeId = '00000000-0000-0000-0000-000000000001';
      }

      // Nettoyage du nom du fichier
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      debugPrint("📦 Upload du fichier : $sanitizedFileName");

      // Vérif doublon via hash
      final hash = md5Hex(bytes);
      debugPrint("🔐 Hash MD5 : $hash");

      final existing = await _db
          .from('mediafile')
          .select('id')
          .eq('filehash', hash)
          .maybeSingle();

      if (existing != null) {
        throw Exception("⚠️ Fichier déjà existant dans la base.");
      }

      // 🧼 Option remove.bg
      Uint8List finalBytes = bytes;
      String finalFileName = sanitizedFileName;

      if (removeBackground) {
        final removeBgApiKey = dotenv.env['REMOVEBG_API_KEY'];
        if (removeBgApiKey != null && removeBgApiKey.isNotEmpty) {
          debugPrint("🎯 Remove.bg activé - Traitement en cours...");
          try {
            final processedBytes = await _removeBg(bytes, removeBgApiKey);
            if (processedBytes != null && processedBytes.isNotEmpty) {
              finalBytes = processedBytes;
              finalFileName = 'no_bg_$sanitizedFileName';
              debugPrint("✅ Remove.bg réussi - Nouvelle taille: ${finalBytes.length} octets");
            } else {
              debugPrint("⚠️ Remove.bg a retourné des données vides - Utilisation de l'original");
            }
          } catch (e) {
            debugPrint("❌ Erreur Remove.bg: $e - Utilisation de l'image originale");
          }
        } else {
          debugPrint("⚠️ Remove.bg activé mais clé API manquante dans .env");
        }
      }

      // Vérification du bucket Supabase
      const bucket = 'media';
      final storage = _db.storage.from(bucket);
      try {
        await storage.list();
      } catch (e) {
        throw Exception("Bucket '$bucket' introuvable dans Supabase Storage !");
      }

      // Upload du fichier
      final storageKey =
          'media_items/$safeId/${DateTime.now().millisecondsSinceEpoch}_$finalFileName';
      final mime = lookupMimeType(finalFileName) ?? 'application/octet-stream';

      await storage.uploadBinary(
        storageKey,
        finalBytes,
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );

      final publicUrl = storage.getPublicUrl(storageKey);
      debugPrint("🌐 Fichier accessible à : $publicUrl");

      // Création du modèle MediaFile
      final record = MediaFile.newLocal(
        mediaitemid: safeId,
        filename: finalFileName,
        filetype: type,
        fileurl: publicUrl,
      );

      // 🔮 AutoTagging avec Hugging Face
      List<String>? autotags;
      try {
        final hfToken = dotenv.env['HUGGINGFACE_TOKEN'];
        if (hfToken != null && hfToken.isNotEmpty) {
          autotags = await AutoTaggingService(apiKey: hfToken).analyzeImage(finalBytes);
          debugPrint("🏷️ Auto-tags générés: ${autotags?.join(', ')}");
        } else {
          debugPrint("⚠️ Token HuggingFace manquant - AutoTagging ignoré");
        }
      } catch (e) {
        debugPrint("⚠️ Erreur AutoTagging: $e");
      }

      // Insertion en base
      final data = record.toJson()
        ..['storagepath'] = storageKey
        ..['filehash'] = hash
        ..['filesize'] = finalBytes.length;

      if (autotags != null && autotags.isNotEmpty) {
        data['autotags'] = autotags;
      }

      await _db.from('mediafile').insert(data);
      debugPrint("✅ Upload réussi: $finalFileName");

      return record;
    });
  }

  // =============================================================
  // ✏️ UPDATE
  // =============================================================
  Future<void> updateFile(MediaFile file) async {
    await SupabaseManager.runWithFreshJwt(() async {
      await _db.from('mediafile').update(file.toJson()).eq('id', file.id);
      debugPrint("✏️ Fichier mis à jour : ${file.filename}");
    });
  }

  // =============================================================
  // 🗑️ DELETE
  // =============================================================
  Future<void> delete(MediaFile file) async {
    await SupabaseManager.runWithFreshJwt(() async {
      final row = await _db
          .from('mediafile')
          .select('storagepath')
          .eq('id', file.id)
          .maybeSingle();

      if (row?['storagepath'] != null) {
        await _db.storage.from('media').remove([row?['storagepath']]);
      }

      await _db.from('mediafile').delete().eq('id', file.id);
      debugPrint("🗑️ Fichier supprimé : ${file.filename}");
    });
  }

  // =============================================================
  // 🔍 GET BY ID
  // =============================================================
  Future<MediaFile?> getById(String id) async {
    return await SupabaseManager.runWithFreshJwt(() async {
      final row = await _db
          .from('mediafile')
          .select()
          .eq('id', id)
          .maybeSingle();

      return row != null ? MediaFile.fromJson(row) : null;
    });
  }

  // =============================================================
  // 📊 STATISTIQUES
  // =============================================================
  Future<Map<String, dynamic>> getStats(String mediaItemId) async {
    return await SupabaseManager.runWithFreshJwt(() async {
      final countResult = await _db
          .from('mediafile')
          .count(CountOption.exact)
          .eq('mediaitemid', mediaItemId);

      final sizeResult = await _db
          .from('mediafile')
          .select('filesize')
          .eq('mediaitemid', mediaItemId);

      final totalSize = (sizeResult as List)
          .fold<int>(0, (sum, item) => sum + (item['filesize'] as int? ?? 0));

      return {
        'count': countResult, // countResult contient directement le nombre
        'totalSize': totalSize,
        'avgSize': totalSize ~/ (countResult > 0 ? countResult : 1),
      };
    });
  }
  // =============================================================
  // 🧼 Remove.bg helper
  // =============================================================
  Future<Uint8List?> _removeBg(Uint8List bytes, String apiKey) async {
    try {
      debugPrint("🧼 Appel Remove.bg API...");

      final uri = Uri.parse('https://api.remove.bg/v1.0/removebg');
      final request = http.MultipartRequest('POST', uri)
        ..headers['X-Api-Key'] = apiKey
        ..fields['size'] = 'auto'
        ..files.add(http.MultipartFile.fromBytes(
            'image_file',
            bytes,
            filename: 'image.jpg'
        ));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resultBytes = await response.stream.toBytes();
        debugPrint("✅ Remove.bg réussi - ${resultBytes.length} octets");
        return resultBytes;
      } else {
        final errorBody = await response.stream.bytesToString();
        debugPrint("❌ Remove.bg erreur ${response.statusCode}: $errorBody");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Erreur Remove.bg: $e");
      return null;
    }
  }
}