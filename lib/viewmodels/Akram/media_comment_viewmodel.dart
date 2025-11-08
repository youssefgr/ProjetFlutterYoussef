import 'package:uuid/uuid.dart';

import '../../Models/Akram/media_models.dart';
import '../../repositories/Akram/media_comment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For VoidCallback

class CommentViewModel {
  List<MediaComment> _comments = [];
  List<MediaComment> get comments => _comments;

  /// Correctly typed callback
  VoidCallback? onCommentsUpdated;

  RealtimeChannel? _subscription;

  Future<void> loadCommentsForMedia(String mediaTitle) async {
    try {
      print('🔍 loadCommentsForMedia called with: $mediaTitle');
      _comments = await CommentRepository.getCommentsForMedia(mediaTitle);
      print('✅ Comments loaded: ${_comments.length}');
      onCommentsUpdated?.call();

      // Unsubscribe previous
      _subscription?.unsubscribe();

      _subscription = CommentRepository.subscribeToComments(
        mediaTitle: mediaTitle,
        onInsert: (comment) {
          print('✅ Comment inserted');
          _comments.add(comment);
          onCommentsUpdated?.call();
        },
        onUpdate: (comment) {
          print('✅ Comment updated');
          final index = _comments.indexWhere((e) => e.id == comment.id);
          if (index != -1) _comments[index] = comment;
          onCommentsUpdated?.call();
        },
        onDelete: (id) {
          print('✅ Comment deleted');
          _comments.removeWhere((e) => e.id == id);
          onCommentsUpdated?.call();
        },
      );
    } catch (e, stackTrace) {
      print('❌ ERROR in loadCommentsForMedia: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> addComment(String mediaItemId, String mediaTitle, String text, double rating) async {
    print('🔍 DEBUG: addComment called');
    print('🔍 mediaItemId: $mediaItemId');
    print('🔍 mediaTitle: $mediaTitle');
    print('🔍 text: $text');
    print('🔍 rating: $rating');

    final user = Supabase.instance.client.auth.currentUser;
    print('🔍 user: $user');

    if (user == null) {
      print('❌ ERROR: No authenticated user!');
      return;
    }

    try {
      final comment = MediaComment(
        id: const Uuid().v4(),
        mediaItemId: mediaItemId,
        mediaTitle: mediaTitle,
        userId: user.id,
        userName: user.userMetadata?['full_name'] ?? user.email!.split('@')[0],
        date: DateTime.now(),
        rating: rating,
        text: text,
      );

      print('🔍 DEBUG: Comment object created');
      print('🔍 Comment: ${comment.toMap()}');

      await CommentRepository.saveComment(comment);
      print('✅ Comment saved successfully');

      _comments.add(comment);
      onCommentsUpdated?.call();
      print('✅ Comments updated');
    } catch (e, stackTrace) {
      print('❌ ERROR in addComment: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> updateComment(MediaComment updatedComment) async {
    await CommentRepository.updateComment(updatedComment);

    final index = _comments.indexWhere((c) => c.id == updatedComment.id);
    if (index != -1) {
      _comments[index] = updatedComment;
      onCommentsUpdated?.call();
    }
  }

  Future<void> deleteComment(String commentId) async {
    await CommentRepository.deleteComment(commentId);
    _comments.removeWhere((c) => c.id == commentId);
    onCommentsUpdated?.call();
  }

  double getAverageRating() {
    if (_comments.isEmpty) return 0.0;
    final total = _comments.fold<double>(0.0, (sum, c) => sum + c.rating);
    return total / _comments.length;
  }

  int get commentsCount => _comments.length;

  void dispose() {
    _subscription?.unsubscribe();
  }
}
