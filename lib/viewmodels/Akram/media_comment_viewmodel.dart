import '../../Models/Akram/media_models.dart';
import '../../repositories/Akram/media_comment_repository.dart';

class CommentViewModel {
  List<MediaComment> _comments = [];
  List<MediaComment> get comments => _comments;

  // State management callbacks
  Function()? onCommentsUpdated;

  // Load comments for specific media item
  Future<void> loadCommentsForMedia(String mediaItemId) async {
    _comments = await CommentRepository.getCommentsForMedia(mediaItemId);
    onCommentsUpdated?.call();
  }

  // Add comment
  Future<void> addComment(MediaComment comment) async {
    final allComments = await CommentRepository.loadComments();
    allComments.add(comment);
    await CommentRepository.saveComments(allComments);
    _comments.add(comment);
    onCommentsUpdated?.call();
  }

  // Update comment
  Future<void> updateComment(MediaComment updatedComment) async {
    final allComments = await CommentRepository.loadComments();
    final index = allComments.indexWhere((comment) => comment.id == updatedComment.id);
    if (index != -1) {
      allComments[index] = updatedComment;
      await CommentRepository.saveComments(allComments);

      final localIndex = _comments.indexWhere((comment) => comment.id == updatedComment.id);
      if (localIndex != -1) {
        _comments[localIndex] = updatedComment;
      }
      onCommentsUpdated?.call();
    }
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    final allComments = await CommentRepository.loadComments();
    allComments.removeWhere((comment) => comment.id == commentId);
    await CommentRepository.saveComments(allComments);

    _comments.removeWhere((comment) => comment.id == commentId);
    onCommentsUpdated?.call();
  }

  // Get average rating for media item
  double getAverageRating() {
    if (_comments.isEmpty) return 0.0;
    final totalRating = _comments.fold(0.0, (sum, comment) => sum + comment.rating);
    return totalRating / _comments.length;
  }

  // Get comments count
  int get commentsCount => _comments.length;
}