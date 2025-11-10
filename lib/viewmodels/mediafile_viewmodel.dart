import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Models/Hajer/mediafile.dart';
import '../repositories/Hajer/mediafile_repository.dart';
import '../utils/supabase_manager.dart';

/// 🧠 ViewModel central — relie l'interface utilisateur au dépôt (repository)
class MediaFileViewModel extends ChangeNotifier {
  final MediaFileRepository _repo = MediaFileRepository();

  /// Liste des fichiers actuellement chargés
  List<MediaFile> files = [];

  /// États UI
  bool loading = false;
  String? error;
  String? infoMessage;

  // =============================================================
  // 🔄 CHARGER TOUS LES FICHIERS D'UN MEDIA ITEM
  // =============================================================
  Future<void> load(String mediaItemId) async {
    _setLoading(true);
    error = null;
    try {
      files = await _repo.fetchByMediaItem(mediaItemId);
      _log('✅ ${files.length} fichiers chargés pour mediaItemId=$mediaItemId');
    } catch (e) {
      error = 'Erreur de chargement : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // 📤 AJOUT LOCAL
  // =============================================================
  Future<void> addFromLocal({
    required String mediaItemId,
    required String filePath,
    FileType type = FileType.poster,
    bool removeBackground = false,
  }) async {
    _setLoading(true);
    error = null;
    try {
      final record = await _repo.createFromLocalFile(
        mediaItemId: mediaItemId,
        filePath: filePath,
        type: type,
        removeBackground: removeBackground,
      );

      files.insert(0, record);
      infoMessage = '📁 Fichier ajouté : ${record.filename}';
      _log(infoMessage!);

      // Recharge pour récupérer autotags après upload
      await load(mediaItemId);
    } catch (e) {
      error = 'Erreur ajout local : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ☁️ AJOUT DEPUIS GOOGLE DRIVE
  // =============================================================
  Future<void> addFromDrive({
    required BuildContext context,
    required String mediaItemId,
    required String driveFileId,
    required String driveFileName,
    FileType type = FileType.poster,
    bool removeBackground = false,
  }) async {
    _setLoading(true);
    error = null;
    try {
      final record = await _repo.createFromGoogleDrive(
        context: context,
        mediaItemId: mediaItemId,
        driveFileId: driveFileId,
        driveFileName: driveFileName,
        type: type,
        removeBackground: removeBackground,
      );

      files.insert(0, record);
      infoMessage = '☁️ Import Drive réussi : ${record.filename}';
      _log(infoMessage!);

      await load(mediaItemId);
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        error = '🔑 Session Google expirée — reconnexion requise.';
        _log(error!, isError: true);

        await SupabaseManager.signInWithGoogle(context);
        infoMessage = '🔐 Reconnecté à Google avec succès.';
        _log(infoMessage!);
      } else {
        error = 'Erreur import Drive : $e';
        _log(error!, isError: true);
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // 📥 AJOUT DEPUIS BYTES (Pinterest, etc.)
  // =============================================================
  Future<void> addFromBytes({
    required String mediaItemId,
    required String fileName,
    required Uint8List bytes,
    FileType type = FileType.poster,
    bool removeBackground = false,
  }) async {
    _setLoading(true);
    error = null;
    try {
      final record = await _repo.createFromBytes(
        mediaItemId: mediaItemId,
        fileName: fileName,
        bytes: bytes,
        type: type,
        removeBackground: removeBackground,
      );

      files.insert(0, record);
      infoMessage = '📁 Fichier ajouté : ${record.filename}';
      _log(infoMessage!);

      await load(mediaItemId);
    } catch (e) {
      error = 'Erreur ajout fichier : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // 🗑️ SUPPRESSION
  // =============================================================
  Future<void> remove(MediaFile file) async {
    _setLoading(true);
    error = null;
    try {
      await _repo.delete(file);
      files.removeWhere((f) => f.id == file.id);
      infoMessage = '🗑️ Fichier supprimé : ${file.filename}';
      _log(infoMessage!);
    } catch (e) {
      error = 'Erreur suppression : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ✏️ MISE À JOUR
  // =============================================================
  Future<void> updateFile(MediaFile updated) async {
    _setLoading(true);
    error = null;
    try {
      await _repo.updateFile(updated);
      final i = files.indexWhere((f) => f.id == updated.id);
      if (i != -1) files[i] = updated;
      infoMessage = '✏️ Fichier mis à jour : ${updated.filename}';
      _log(infoMessage!);
    } catch (e) {
      error = 'Erreur mise à jour : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // 🔍 RECHERCHER PAR ID
  // =============================================================
  Future<MediaFile?> getById(String id) async {
    try {
      return await _repo.getById(id);
    } catch (e) {
      _log('❌ Erreur récupération fichier $id: $e', isError: true);
      return null;
    }
  }

  // =============================================================
  // 📊 STATISTIQUES
  // =============================================================
  Future<Map<String, dynamic>> getStats(String mediaItemId) async {
    try {
      return await _repo.getStats(mediaItemId);
    } catch (e) {
      _log('❌ Erreur statistiques: $e', isError: true);
      return {'count': 0, 'totalSize': 0, 'avgSize': 0};
    }
  }

  // =============================================================
  // 🧹 NETTOYAGE DES ERREURS/MESSAGES
  // =============================================================
  void clearError() {
    error = null;
    notifyListeners();
  }

  void clearInfo() {
    infoMessage = null;
    notifyListeners();
  }

  void clearAllMessages() {
    error = null;
    infoMessage = null;
    notifyListeners();
  }

  // =============================================================
  // 🔄 RECHARGEMENT
  // =============================================================
  Future<void> refresh(String mediaItemId) async {
    await load(mediaItemId);
  }

  // =============================================================
  // 🔧 HELPERS INTERNES
  // =============================================================
  void _setLoading(bool v) {
    loading = v;
    notifyListeners();
  }

  void _log(String msg, {bool isError = false}) {
    if (kDebugMode) {
      final prefix = isError ? '❌ ERROR' : 'ℹ️ INFO';
      debugPrint('$prefix | MediaFileVM | $msg');
    }
  }

  // =============================================================
  // 🧮 GETTERS UTILES
  // =============================================================
  int get fileCount => files.length;

  bool get hasFiles => files.isNotEmpty;

  bool get hasError => error != null;

  bool get hasInfo => infoMessage != null;

  List<MediaFile> get filesWithTags =>
      files.where((f) => f.autotags != null && f.autotags!.isNotEmpty).toList();

  List<MediaFile> get filesWithoutTags =>
      files.where((f) => f.autotags == null || f.autotags!.isEmpty).toList();
}