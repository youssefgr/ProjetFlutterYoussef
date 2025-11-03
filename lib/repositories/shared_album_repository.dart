import 'package:projetflutteryoussef/Models/Hajer/sharedalbum.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SharedAlbumRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> createAlbum(SharedAlbum album) async {
    await _db.from('sharedalbum').insert(album.toJson());
  }

  Future<List<SharedAlbum>> fetchAlbumsForUser(String userId) async {
    final res = await _db
        .from('sharedalbum')
        .select()
        .contains('sharedWithUserIds', [userId]);

    return (res as List).map((e) => SharedAlbum.fromJson(e)).toList();
  }

  Future<void> addUserToAlbum(String albumId, String userId) async {
    final res =
        await _db.from('sharedalbum').select().eq('id', albumId).maybeSingle();
    if (res == null) return;

    final album = SharedAlbum.fromJson(res);
    final updatedList = List<String>.from(album.sharedWithUserIds)..add(userId);

    await _db
        .from('sharedalbum')
        .update({'sharedWithUserIds': updatedList}).eq('id', albumId);
  }
}
