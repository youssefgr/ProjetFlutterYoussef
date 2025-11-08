import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Models/Akram/media_models.dart';

class CommentRepository {
  static const _table = 'comments';
  static final _client = Supabase.instance.client;

  // Load all comments
  static Future<List<MediaComment>> loadComments() async {
    try {
      final response = await _client.from(_table).select();
      final data = response as List<dynamic>;
      return data.map((e) => _mapRowToComment(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Error loading comments: $e');
      return [];
    }
  }

  // Get comments for specific media item
  static Future<List<MediaComment>> getCommentsForMedia(
      String mediaTitle) async {
    final allComments = await loadComments();
    return allComments.where((c) => c.mediaTitle == mediaTitle).toList();
  }

  // Save comment
  static Future<void> saveComment(MediaComment comment) async {
    try {
      if (kDebugMode) {
        print('🔍 Attempting to save comment: ${comment.toMap()}');
      }
      final response = await _client.from(_table).insert(comment.toMap());
      if (kDebugMode) {
        print('✅ Comment saved successfully: $response');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving comment: $e');
      }
      if (kDebugMode) {
        print('❌ Full error details: ${e.toString()}');
      }
    }
  }

  // Update comment
  static Future<void> updateComment(MediaComment comment) async {
    try {
      await _client.from(_table)
          .update(comment.toMap())
          .eq('id', comment.id);
    } catch (e) {
      if (kDebugMode) print('Error updating comment: $e');
    }
  }

  // Delete comment
  static Future<void> deleteComment(String commentId) async {
    try {
      await _client.from(_table).delete().eq('id', commentId);
    } catch (e) {
      if (kDebugMode) print('Error deleting comment: $e');
    }
  }

  // Real-time subscription for a media item
  static RealtimeChannel subscribeToComments({
    required String mediaTitle, // Changed from mediaItemId
    required void Function(MediaComment comment) onInsert,
    void Function(MediaComment comment)? onUpdate,
    void Function(String id)? onDelete,
  }) {
    final channel = _client.channel('public:$_table');

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'media_title', // Changed from media_item_id
      value: mediaTitle,
    );

    // Insert
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: _table,
      filter: filter,
      callback: (payload) {
        final comment = _mapRowToComment(payload.newRecord);
        onInsert(comment);
      },
    );

    // Update
    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: _table,
        filter: filter,
        callback: (payload) => onUpdate(_mapRowToComment(payload.newRecord)),
      );
    }

    // Delete
    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: _table,
        filter: filter,
        callback: (payload) {
          final id = payload.oldRecord['id'] as String;
          onDelete(id);
        },
      );
    }

    channel.subscribe();
    return channel;
  }

  static MediaComment _mapRowToComment(Map<String, dynamic> row) {
    return MediaComment(
      id: row['id'],
      mediaItemId: row['media_item_id'],
      mediaTitle: row['media_title'],
      // ✅ Read from database
      userId: row['user_id'],
      userName: row['user_name'],
      date: DateTime.parse(row['created_at']),
      rating: (row['rating'] as num).toDouble(),
      text: row['text'],
    );
  }
}