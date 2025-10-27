import 'package:flutter/foundation.dart';
import '../Models/Hajer/mediafile.dart';
import '../repositories/mediafile_repository.dart';

/// 🧠 ViewModel : relie l’interface utilisateur au dépôt (repository)
/// Gère la logique métier + état UI (chargement, erreurs, notifications)
class MediaFileViewModel extends ChangeNotifier {
  final MediaFileRepository _repo = MediaFileRepository();

  /// Liste actuelle des fichiers média liés à un MediaItem
  List<MediaFile> files = [];

  /// États de chargement et erreurs
  bool loading = false;
  String? error;

  /// 🔄 Chargement de tous les fichiers d’un MediaItem
  Future<void> load(String mediaItemId) async {
    _setLoading(true);
    try {
      files = await _repo.fetchByMediaItem(mediaItemId);
      _log('✅ ${files.length} fichiers chargés pour mediaItemId=$mediaItemId');
    } catch (e) {
      error = 'Erreur lors du chargement : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  /// 📤 Ajout d’un fichier depuis l’appareil local
  Future<void> addFromLocal({
    required String mediaItemId,
    required String filePath,
    FileType type = FileType.poster,
    bool removeBackground = false,
    String? removeBgApiKey,
  }) async {
    _setLoading(true);
    try {
      final record = await _repo.createFromLocalFile(
        mediaItemId: mediaItemId,
        filePath: filePath,
        type: type,
        removeBackground: removeBackground,
        removeBgApiKey: removeBgApiKey,
      );
      files.insert(0, record);
      _log('📁 Fichier local ajouté : ${record.filename}');
    } catch (e) {
      error = 'Erreur lors de l’ajout local : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  /// ☁️ Ajout d’un fichier importé depuis Google Drive
  Future<void> addFromDrive({
    required String mediaItemId,
    required String driveFileId,
    required String driveFileName,
    FileType type = FileType.poster,
    bool removeBackground = false,
    String? removeBgApiKey,
  }) async {
    _setLoading(true);
    try {
      final record = await _repo.createFromGoogleDrive(
        mediaItemId: mediaItemId,
        driveFileId: driveFileId,
        driveFileName: driveFileName,
        type: type,
        removeBackground: removeBackground,
        removeBgApiKey: removeBgApiKey,
      );
      files.insert(0, record);
      _log('☁️ Import Drive réussi : ${record.filename}');
    } catch (e) {
      error = 'Erreur import Drive : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  /// ❌ Suppression d’un fichier (DB + Storage)
  Future<void> remove(MediaFile file) async {
    _setLoading(true);
    try {
      await _repo.delete(file);
      files.removeWhere((f) => f.id == file.id);
      _log('🗑️ Fichier supprimé : ${file.filename}');
    } catch (e) {
      error = 'Erreur suppression : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  /// ✏️ Mise à jour d’un fichier (future feature : modification metadata)
  Future<void> updateFile(MediaFile updated) async {
    _setLoading(true);
    try {
      await _repo.update(updated);
      final index = files.indexWhere((f) => f.id == updated.id);
      if (index != -1) files[index] = updated;
      _log('✏️ Fichier mis à jour : ${updated.filename}');
    } catch (e) {
      error = 'Erreur mise à jour : $e';
      _log(error!, isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // 🔧 Helpers internes
  // ------------------------------------------------------------

  void _setLoading(bool value) {
    loading = value;
    notifyListeners();
  }

  void _log(String message, {bool isError = false}) {
    if (kDebugMode) {
      final tag = isError ? '❌ ERROR' : 'ℹ️ INFO';
      debugPrint('$tag | MediaFileVM | $message');
    }
  }
}
