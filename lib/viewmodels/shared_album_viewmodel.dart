import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/Hajer/sharedalbum.dart';
import '../repositories/shared_album_repository.dart';

class SharedAlbumViewModel extends ChangeNotifier {
  final repo = SharedAlbumRepository();
  List<SharedAlbum> albums = [];
  bool loading = false;
  String? error;

  Future<void> load(String userId) async {
    loading = true;
    notifyListeners();
    try {
      albums = await repo.fetchAlbumsForUser(userId);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> create(SharedAlbum album) async {
    try {
      await repo.createAlbum(album);
      albums.insert(0, album);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
