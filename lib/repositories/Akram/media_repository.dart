import 'package:flutter/foundation.dart';
import '../../Models/Akram/media_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaRepository {
  static const String _tableName = 'Media';
  static const String _usersTableName = 'Users';

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

  // Load media items for current logged-in user
  static Future<List<MediaItem>> loadUserMediaItems() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) print('⚠️ No user logged in');
        return [];
      }

      if (kDebugMode) print('📥 Loading media for user: $userId');

      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('userId', userId);

      if (kDebugMode) {
        print('📥 Loaded ${(response as List).length} user media items');
      }

      if (response == null) return [];

      final data = response as List<dynamic>;
      return data.map((item) => _mediaItemFromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading user media data: $e');
      }
      return [];
    }
  }

  // Create/sync user profile on first Google login
  static Future<void> syncUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final userId = user.id;
      final email = user.email ?? '';
      final name = user.userMetadata?['full_name'] ?? email.split('@')[0];

      // Check if user already exists
      final existing = await Supabase.instance.client
          .from(_usersTableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        // Create new user profile
        await Supabase.instance.client
            .from(_usersTableName)
            .insert({
          'id': userId,
          'email': email,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        });

        if (kDebugMode) {
          print('✅ User profile created: $email');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error syncing user profile: $e');
      }
    }
  }

  // Add media item to Supabase
  static Future<void> addMediaItem(MediaItem mediaItem) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final itemData = _mediaItemToJson(mediaItem);
      itemData['userId'] = userId;

      if (kDebugMode) {
        print('📤 Adding media item: ${mediaItem.title}');
        print('Data: $itemData');
      }

      final response = await Supabase.instance.client
          .from(_tableName)
          .insert(itemData)
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

      if (kDebugMode) {
        print('✅ Media item updated: ${mediaItem.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating media: $e');
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

      if (kDebugMode) {
        print('✅ Media item deleted: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting media: $e');
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
      'genre': item.genre.name,
      'userId': item.userId,
    };
  }

  // Convert JSON from Supabase to MediaItem
  static MediaItem _mediaItemFromJson(Map<String, dynamic> json) {
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