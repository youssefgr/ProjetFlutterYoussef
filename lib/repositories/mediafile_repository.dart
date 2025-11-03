import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Models/Hajer/mediafile.dart';
import '../services/drive_service.dart';
import '../services/auto_tagging_service.dart';
import '../utils/hash_utils.dart';
import '../utils/supabase_manager.dart';

/// 🧩 Repository : couche métier pour gérer les fichiers média
/// Gère les interactions entre Supabase (DB + Storage) et les services externes
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
    String? removeBgApiKey,
  }) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final bytes = await File(filePath).readAsBytes();

    return _createFromBytes(
      mediaItemId: mediaItemId,
      fileName: fileName,
      bytes: bytes,
      type: type,
      removeBackground: removeBackground,
      removeBgApiKey: removeBgApiKey,
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
    String? removeBgApiKey,
  }) async {
    final drive = DriveService();
    debugPrint("☁️ Téléchargement depuis Drive : $driveFileName ($driveFileId)");

    Uint8List bytes;
    try {
      bytes = await drive.downloadFileBytes(context, driveFileId);
    } catch (e) {
      // Gestion d’un token expiré
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        throw Exception("⚠️ Token Google expiré — reconnecte-toi manuellement.");
      }
      rethrow;
    }

    if (bytes.isEmpty) {
      throw Exception("❌ Fichier Drive vide ou inaccessible ($driveFileName)");
    }

    return _createFromBytes(
      mediaItemId: mediaItemId,
      fileName: driveFileName,
      bytes: bytes,
      type: type,
      removeBackground: removeBackground,
      removeBgApiKey: removeBgApiKey,
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
    String? removeBgApiKey,
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
      if (removeBackground && removeBgApiKey?.isNotEmpty == true) {
        finalBytes = await _removeBg(bytes, removeBgApiKey!);
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
          'media_items/$safeId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      final mime = lookupMimeType(fileName) ?? 'application/octet-stream';

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
        filename: sanitizedFileName,
        filetype: type,
        fileurl: publicUrl,
      );

      // 🔮 AutoTagging avec Hugging Face
      try {
        final tags = await AutoTaggingService(
          apiKey: dotenv.env['HUGGINGFACE_TOKEN']!,
        ).analyzeImage(finalBytes);


        final data = record.toJson()
          ..['storagepath'] = storageKey
          ..['filehash'] = hash
          ..['filesize'] = finalBytes.length
          ..['autotags'] = tags;

        await _db.from('mediafile').insert(data);
        debugPrint("✅ Upload + tags automatiques OK.");
      } catch (e) {
        debugPrint("⚠️ AutoTagging ignoré : $e");
        final data = record.toJson()
          ..['storagepath'] = storageKey
          ..['filehash'] = hash
          ..['filesize'] = finalBytes.length;
        await _db.from('mediafile').insert(data);
      }

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
  // 🧼 Remove.bg helper
  // =============================================================
  Future<Uint8List> _removeBg(Uint8List bytes, String apiKey) async {
    final uri = Uri.parse('https://api.remove.bg/v1.0/removebg');
    final req = http.MultipartRequest('POST', uri)
      ..headers['X-Api-Key'] = apiKey
      ..fields['size'] = 'auto'
      ..files.add(
        http.MultipartFile.fromBytes('image_file', bytes, filename: 'image.png'),
      );

    final res = await req.send();
    if (res.statusCode == 200) {
      debugPrint("🧼 remove.bg OK");
      return Uint8List.fromList(await res.stream.toBytes());
    }
    debugPrint("⚠️ remove.bg erreur ${res.statusCode}");
    return bytes;
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
}
