import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Models/Hajer/mediafile.dart';
import '../repositories/mediafile_repository.dart';
import '../utils/supabase_manager.dart';

/// 🧠 ViewModel central — relie l'interface utilisateur au dépôt (repository)
/// Gère :
class MediaFileViewModel extends ChangeNotifier {
  final MediaFileRepository _repo = MediaFileRepository();

  /// Liste des fichiers actuellement chargés
  List<MediaFile> files = [];

  /// États UI
  bool loading = false;
  String? error;
  String? infoMessage;

  // =============================================================
  // 🔄 CHARGER TOUS LES FICHIERS D’UN MEDIA ITEM
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
    String? removeBgApiKey,
  }) async {
    _setLoading(true);
    error = null;
    try {
      final record = await _repo.createFromLocalFile(
        mediaItemId: mediaItemId,
        filePath: filePath,
        type: type,
        removeBackground: removeBackground,
        removeBgApiKey: removeBgApiKey,
      );

      files.insert(0, record);
      infoMessage = '📁 Fichier ajouté : ${record.filename}';
      _log(infoMessage!);

      // ✅ Recharge pour récupérer autotags après upload local
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
    String? removeBgApiKey,
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
        removeBgApiKey: removeBgApiKey,
      );

      files.insert(0, record);
      infoMessage = '☁️ Import Drive réussi : ${record.filename}';
      _log(infoMessage!);

      // ✅ Recharge après import pour rafraîchir les autotags depuis Supabase
      await load(mediaItemId);
    } catch (e) {
      if (e.toString().contains('GOOGLE_RELOGIN_REQUIRED')) {
        error = '🔑 Session Google expirée — reconnexion requise.';
        _log(error!, isError: true);

        // ✅ Relance la connexion Google
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
  // ✏️ MISE À JOUR (future feature)
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
}
