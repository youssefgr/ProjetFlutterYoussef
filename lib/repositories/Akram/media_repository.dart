import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../Models/Akram/media_models.dart';

class MediaRepository {
  static const String _fileName = 'media_data.json';

  // Get the file where media data is stored
  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Save media items to local storage
  static Future<void> saveMediaItems(List<MediaItem> mediaItems) async {
    try {
      final file = await _getLocalFile();
      final jsonList = mediaItems.map((item) => _mediaItemToJson(item)).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving media data: $e');
      }
    }
  }

  // Load media items from local storage
  static Future<List<MediaItem>> loadMediaItems() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList.map((json) => _mediaItemFromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading media data: $e');
      }
    }
    return [];
  }

  // Convert MediaItem to JSON
  static Map<String, dynamic> _mediaItemToJson(MediaItem item) {
    return {
      'id': item.id,
      'category': item.category.index,
      'title': item.title,
      'posterUrl': item.imageUrl,
      'releaseDate': item.releaseDate.millisecondsSinceEpoch,
      'description': item.description,
      'status': item.status.index,
      'genres': item.genres.map((genre) => genre.index).toList(),
    };
  }

  // Convert JSON to MediaItem
  static MediaItem _mediaItemFromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      category: MediaCategory.values[json['category']],
      title: json['title'],
      imageUrl: json['posterUrl'],
      releaseDate: DateTime.fromMillisecondsSinceEpoch(json['releaseDate']),
      description: json['description'],
      status: MediaViewStatus.values[json['status']],
      genres: (json['genres'] as List).map((index) => MediaGenre.values[index]).toList(),
    );
  }
}