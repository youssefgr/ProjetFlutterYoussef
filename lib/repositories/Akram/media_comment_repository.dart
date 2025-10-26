import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../Models/Akram/media_models.dart';

class CommentRepository {
  static const String _fileName = 'comments_data.json';

  // Get the file where comments are stored
  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Save comments to local storage
  static Future<void> saveComments(List<MediaComment> comments) async {
    try {
      final file = await _getLocalFile();
      final jsonList = comments.map((comment) => _commentToJson(comment)).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving comments: $e');
      }
    }
  }

  // Load comments from local storage
  static Future<List<MediaComment>> loadComments() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList.map((json) => _commentFromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading comments: $e');
      }
    }
    return [];
  }

  // Get comments for specific media item
  static Future<List<MediaComment>> getCommentsForMedia(String mediaItemId) async {
    final allComments = await loadComments();
    return allComments.where((comment) => comment.mediaItemId == mediaItemId).toList();
  }

  // Convert MediaComment to JSON
  static Map<String, dynamic> _commentToJson(MediaComment comment) {
    return {
      'id': comment.id,
      'mediaItemId': comment.mediaItemId,
      'userId': comment.userId,
      'userName': comment.userName,
      'date': comment.date.millisecondsSinceEpoch,
      'rating': comment.rating,
      'text': comment.text,
    };
  }

  // Convert JSON to MediaComment
  static MediaComment _commentFromJson(Map<String, dynamic> json) {
    return MediaComment(
      id: json['id'],
      mediaItemId: json['mediaItemId'],
      userId: json['userId'],
      userName: json['userName'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      rating: json['rating'].toDouble(),
      text: json['text'],
    );
  }
}