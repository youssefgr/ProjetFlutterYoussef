import 'package:flutter/foundation.dart';
import '../../Models/Akram/media_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaRepository {
  static const String _tableName = 'Media';

  // Load ALL media items from Supabase
  static Future<List<MediaItem>> loadMediaItems() async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select();

      if (kDebugMode) {
        print('📥 Loaded ${(response as List).length} media items from Supabase');
        print('Raw data: $response');
      }

      if (response == null) return [];

      final data = response as List<dynamic>;
      return data.map((item) => _mediaItemFromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading media data: $e');
      }
      return [];
    }
  }

  // Add media item to Supabase
  static Future<void> addMediaItem(MediaItem mediaItem) async {
    try {
      if (kDebugMode) {
        print('📤 Adding media item: ${mediaItem.title}');
        print('Data: ${_mediaItemToJson(mediaItem)}');
      }

      final response = await Supabase.instance.client
          .from(_tableName)
          .insert(_mediaItemToJson(mediaItem))
          .select();

      if (kDebugMode) {
        print('✅ Media item added successfully: $response');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding media: $e');
      }
      rethrow;
    }
  }

  // Update media item in Supabase
  static Future<void> updateMediaItem(MediaItem mediaItem) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .update(_mediaItemToJson(mediaItem))
          .eq('id', mediaItem.id);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating media: $e');
      }
      rethrow;
    }
  }

  // Delete media item from Supabase
  static Future<void> deleteMediaItem(String id) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .delete()
          .eq('id', id);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting media: $e');
      }
      rethrow;
    }
  }

  // Convert MediaItem to JSON for Supabase
  static Map<String, dynamic> _mediaItemToJson(MediaItem item) {
    return {
      'id': item.id,
      'category': item.category.name,
      'title': item.title,
      'imageUrl': item.imageUrl,
      'releaseDate': item.releaseDate.toIso8601String(),
      'description': item.description,
      'status': item.status.name,
      'genre': item.genre.name, // Single genre as string
      'userId': item.userId,
    };
  }

  // Convert JSON from Supabase to MediaItem
  static MediaItem _mediaItemFromJson(Map<String, dynamic> json) {
    // Handle both int and String ids
    final id = json['id'];
    final idString = id is int ? id.toString() : id as String;

    if (kDebugMode) {
      print('🔍 Parsing media item:');
      print('  ID type: ${json['id'].runtimeType}');
      print('  Genre type: ${json['genre'].runtimeType}');
      print('  Genre value: ${json['genre']}');
    }

    return MediaItem(
      id: idString,
      category: MediaCategory.values.firstWhere(
            (e) => e.name == json['category'],
        orElse: () => MediaCategory.movie,
      ),
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      releaseDate: DateTime.parse(json['releaseDate'] as String),
      description: json['description'] as String? ?? '',
      status: MediaViewStatus.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => MediaViewStatus.toView,
      ),
      genre: MediaGenre.values.firstWhere(
            (e) => e.name == json['genre'],
        orElse: () => MediaGenre.action,
      ),
      userId: json['userId'] as String,
    );
  }
}