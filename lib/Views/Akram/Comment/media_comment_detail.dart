import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../viewmodels/Akram/media_comment_viewmodel.dart';
import 'media_comment_views.dart';

class MediaCommentDetail extends StatefulWidget {
  final String mediaItemId;
  final String mediaTitle;
  final CommentViewModel commentViewModel;

  const MediaCommentDetail({
    super.key,
    required this.mediaItemId,
    required this.mediaTitle,
    required this.commentViewModel,
  });

  @override
  State<MediaCommentDetail> createState() => _MediaCommentDetailState();
}

class _MediaCommentDetailState extends State<MediaCommentDetail> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.commentViewModel.onCommentsUpdated = () {
      if (mounted) setState(() => _loading = false);
    };
    _loadComments();
  }

  Future<void> _loadComments() async {
    await widget.commentViewModel.loadCommentsForMedia(widget.mediaTitle);
  }

  Color _getAvatarColor(String name) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
  }

  bool _isUserComment(MediaComment comment) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return currentUser != null && currentUser.id == comment.userId;
  }

  Widget _buildComment(MediaComment comment) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: _getAvatarColor(comment.userName),
              child: Text(
                comment.userName[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${comment.date.day}/${comment.date.month}/${comment.date.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            StarRating(
              size: 20,
              rating: comment.rating,
              color: Colors.amber,
              borderColor: Colors.grey[300],
              starCount: 5,
              onRatingChanged: null,
            ),
          ]),
          const SizedBox(height: 12),
          Text(comment.text, style: const TextStyle(fontSize: 14, height: 1.4)),

          // Edit/Delete buttons - only show for user's own comments
          if (_isUserComment(comment))
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit comment',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => MediaEditComment(
                      comment: comment,
                      onCommentUpdated: (updatedComment) async {
                        await widget.commentViewModel.updateComment(updatedComment);
                        await _loadComments();
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  tooltip: 'Delete comment',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => MediaDeleteComment(
                      comment: comment,
                      onCommentDeleted: () async {
                        await widget.commentViewModel.deleteComment(comment.id);
                        await _loadComments();
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final avgRating = widget.commentViewModel.getAverageRating();
    final comments = widget.commentViewModel.comments;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Average Rating
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  avgRating > 0 ? '${avgRating.toStringAsFixed(1)}/5' : 'No ratings yet',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (comments.isNotEmpty)
                  Text(
                    'Based on ${comments.length} ${comments.length == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
              ]),
              if (avgRating > 0) ...[
                const Spacer(),
                Column(
                  children: [
                    StarRating(
                      size: 20,
                      rating: avgRating,
                      color: Colors.amber,
                      borderColor: Colors.grey[300],
                      starCount: 5,
                      onRatingChanged: null,
                    ),
                    Text(
                      '${(avgRating / 5 * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Reviews & Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_comment, size: 18),
          label: const Text('Add Review'),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => MediaAddComment(
              mediaItemId: widget.mediaItemId,
              onCommentAdded: (comment) {
                widget.commentViewModel.addComment(
                    widget.mediaItemId,
                    widget.mediaTitle,
                    comment.text,
                    comment.rating
                );
              },
            ),
          ),
        ),
      ]),
      const SizedBox(height: 16),

      // Content
      _loading
          ? const Center(child: CircularProgressIndicator())
          : comments.isEmpty
          ? _buildEmptyState()
          : Column(children: comments.map(_buildComment).toList()),
    ]);
  }

  Widget _buildEmptyState() => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.comment, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No reviews yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts about "${widget.mediaTitle}"!',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_comment),
            label: const Text('Write First Review'),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => MediaAddComment(
                mediaItemId: widget.mediaItemId,
                onCommentAdded: (comment) {
                  widget.commentViewModel.addComment(
                      widget.mediaItemId,
                      widget.mediaTitle,
                      comment.text,
                      comment.rating
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    widget.commentViewModel.dispose();
    super.dispose();
  }
}