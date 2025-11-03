import 'package:projetflutteryoussef/Models/Akram/media_models.dart';
import 'package:projetflutteryoussef/repositories/media_repository.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';

class MediaViewModel {
  List<MediaItem> _mediaItems = [];
  List<MediaItem> get mediaItems => _mediaItems;

  // State management callbacks
  Function()? onMediaItemsUpdated;

  // Load media items
  Future<void> loadMediaItems() async {
    _mediaItems = await MediaRepository.loadMediaItems();
    onMediaItemsUpdated?.call();
  }

  // Add media item
  Future<void> addMediaItem(MediaItem item) async {
    _mediaItems.add(item);
    await MediaRepository.saveMediaItems(_mediaItems);
    onMediaItemsUpdated?.call();
  }

  // Update media item
  Future<void> updateMediaItem(MediaItem updatedItem) async {
    final index = _mediaItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _mediaItems[index] = updatedItem;
      await MediaRepository.saveMediaItems(_mediaItems);
      onMediaItemsUpdated?.call();
    }
  }

  // Delete media item
  Future<void> deleteMediaItem(String id) async {
    final item = _mediaItems.firstWhere((item) => item.id == id);
    if (item.posterUrl.isNotEmpty) {
      await ImageUtils.deleteImage(item.posterUrl);
    }
    _mediaItems.removeWhere((item) => item.id == id);
    await MediaRepository.saveMediaItems(_mediaItems);
    onMediaItemsUpdated?.call();
  }

  // Update status via drag & drop
  Future<void> updateMediaStatus(String itemId, MediaViewStatus newStatus) async {
    final index = _mediaItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _mediaItems[index] = _mediaItems[index].copyWith(status: newStatus);
      await MediaRepository.saveMediaItems(_mediaItems);
      onMediaItemsUpdated?.call();
    }
  }

  // Get items by status
  List<MediaItem> getItemsByStatus(MediaViewStatus status) {
    return _mediaItems.where((item) => item.status == status).toList();
  }
}