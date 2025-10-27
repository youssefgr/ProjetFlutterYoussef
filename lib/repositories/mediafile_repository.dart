import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Models/Hajer/mediafile.dart';
import '../services/drive_service.dart';
import '../utils/hash_utils.dart';
import '../utils/supabase_manager.dart';

class MediaFileRepository {
  final SupabaseClient _db = SupabaseManager.client;

  // ===================== READ =====================
  Future<List<MediaFile>> fetchByMediaItem(String mediaItemId) async {
    final rows = await _db
        .from('mediafile')
        .select()
        .eq('mediaitemid', mediaItemId)
        .order('uploaddate', ascending: false);

    return (rows as List).map((e) => MediaFile.fromJson(e)).toList();
  }

  // ===================== CREATE: Local picker =====================
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

  // ===================== CREATE: Google Drive import =====================
  Future<MediaFile> createFromGoogleDrive({
    required String mediaItemId,
    required String driveFileId,
    required String driveFileName,
    FileType type = FileType.poster,
    bool removeBackground = false,
    String? removeBgApiKey,
  }) async {
    final drive = DriveService();

    debugPrint("☁️ Téléchargement du fichier Google Drive : $driveFileName ($driveFileId)");
    final bytes = await drive.downloadFileBytes(driveFileId);

    if (bytes.isEmpty) {
      throw Exception("❌ Le fichier Drive est vide ou inaccessible ($driveFileName)");
    }

    debugPrint("📦 Taille du fichier Drive : ${bytes.lengthInBytes} octets");

    return _createFromBytes(
      mediaItemId: mediaItemId,
      fileName: driveFileName,
      bytes: bytes,
      type: type,
      removeBackground: removeBackground,
      removeBgApiKey: removeBgApiKey,
    );
  }

  // ===================== CORE: Upload + Insert DB =====================
  Future<MediaFile> _createFromBytes({
    required String mediaItemId,
    required String fileName,
    required Uint8List bytes,
    required FileType type,
    required bool removeBackground,
    String? removeBgApiKey,
  }) async {
    try {
      if (bytes.isEmpty) throw Exception("❌ Données vides — rien à uploader.");

      // Sécurisation de l’ID media
      final safeMediaItemId = (mediaItemId.isEmpty ||
        mediaItemId == '00000000-0000-0000-0000-000000000001')
    ? '00000000-0000-0000-0000-000000000001' // UUID valide par défaut
    : mediaItemId;


      // Nettoyage du nom de fichier (évite accents, espaces et caractères interdits)
      final sanitizedFileName =
          fileName.replaceAll(RegExp(r'[^\w\.-]'), '_'); // garde lettres, chiffres, _ et .

      debugPrint("📦 Upload de $sanitizedFileName (${bytes.lengthInBytes} octets) vers Supabase...");

      // Vérification de doublon par hash MD5
      final hash = md5Hex(bytes);
      debugPrint("🔐 Hash MD5 = $hash");

      final exist = await _db
          .from('mediafile')
          .select('id')
          .eq('filehash', hash)
          .maybeSingle();

      if (exist != null) {
        throw Exception('⚠️ Doublon détecté : un fichier identique existe déjà.');
      }

      // Option remove.bg
      Uint8List finalBytes = bytes;
      if (removeBackground && removeBgApiKey?.isNotEmpty == true) {
        finalBytes = await _removeBg(bytes, removeBgApiKey!);
      }

      // Bucket
      const bucketName = 'media';
      final storage = _db.storage.from(bucketName);

      try {
        await storage.list(); // vérifie l'existence du bucket
      } catch (e) {
        throw Exception("Bucket '$bucketName' introuvable. Crée-le dans Supabase → Storage.");
      }

      // Upload
      final storageKey =
          'media_items/$safeMediaItemId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      final mime = lookupMimeType(fileName) ?? 'application/octet-stream';

      await storage.uploadBinary(
        storageKey,
        finalBytes,
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );

      final publicUrl = storage.getPublicUrl(storageKey);
      debugPrint("🌐 URL publique : $publicUrl");

      // Insertion DB
      final record = MediaFile.newLocal(
        mediaitemid: safeMediaItemId,
        filename: sanitizedFileName,
        filetype: type,
        fileurl: publicUrl,
      );

      final data = record.toJson()
        ..['storagepath'] = storageKey
        ..['filehash'] = hash
        ..['filesize'] = finalBytes.length;

      await _db.from('mediafile').insert(data);
      debugPrint("✅ Insertion DB réussie pour $sanitizedFileName");

      return record;
    } catch (e, st) {
      debugPrint("❌ ERREUR DANS _createFromBytes : $e");
      debugPrint(st.toString());
      rethrow;
    }
  }

  // ===================== UPDATE =====================
  Future<void> update(MediaFile file) async {
    await _db.from('mediafile').update(file.toJson()).eq('id', file.id);
  }

  // ===================== DELETE =====================
  Future<void> delete(MediaFile file) async {
    final row = await _db
        .from('mediafile')
        .select('storagepath')
        .eq('id', file.id)
        .maybeSingle();

    if (row != null && row['storagepath'] != null) {
      await _db.storage.from('media').remove([row['storagepath'] as String]);
    }

    await _db.from('mediafile').delete().eq('id', file.id);
    debugPrint("🗑️ Fichier supprimé : ${file.filename}");
  }

  // ===================== REMOVE.BG helper =====================
  Future<Uint8List> _removeBg(Uint8List bytes, String apiKey) async {
    final uri = Uri.parse('https://api.remove.bg/v1.0/removebg');
    final req = http.MultipartRequest('POST', uri)
      ..headers['X-Api-Key'] = apiKey
      ..fields['size'] = 'auto'
      ..files.add(http.MultipartFile.fromBytes('image_file', bytes, filename: 'image.png'));

    final res = await req.send();
    if (res.statusCode == 200) {
      debugPrint("🧼 Arrière-plan retiré avec succès (remove.bg)");
      return Uint8List.fromList(await res.stream.toBytes());
    } else {
      debugPrint("⚠️ Erreur remove.bg : ${res.statusCode} — on garde l'image originale.");
      return bytes;
    }
  }
}
