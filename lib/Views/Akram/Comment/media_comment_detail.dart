import 'package:flutter/material.dart';
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
  bool _commentsLoading = true;

  @override
  void initState() {
    super.initState();
    widget.commentViewModel.onCommentsUpdated = _onCommentsUpdated;
    _loadComments();
  }

  void _onCommentsUpdated() {
    setState(() {
      _commentsLoading = false;
    });
  }

  Future<void> _loadComments() async {
    await widget.commentViewModel.loadCommentsForMedia(widget.mediaItemId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average Rating
        _buildAverageRating(),
        const SizedBox(height: 16),

        // Comments Section Header
        _buildCommentsHeader(),
        const SizedBox(height: 16),

        // Comments List
        _buildCommentsContent(),
      ],
    );
  }

  Widget _buildAverageRating() {
    final averageRating = widget.commentViewModel.getAverageRating();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  averageRating > 0 ? '${averageRating.toStringAsFixed(1)}/5' : 'No ratings yet',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (widget.commentViewModel.commentsCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Based on ${widget.commentViewModel.commentsCount} ${widget.commentViewModel.commentsCount == 1 ? 'review' : 'reviews'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ],
            ),
            const Spacer(),
            if (averageRating > 0) ...[
              _buildRatingBar(averageRating),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(double averageRating) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: averageRating / 5,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${(averageRating / 5 * 100).toInt()}%',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCommentsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Reviews & Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_comment, size: 18),
          label: const Text('Add Review'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => MediaAddComment(
                mediaItemId: widget.mediaItemId,
                onCommentAdded: (newComment) {
                  widget.commentViewModel.addComment(newComment);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentsContent() {
    if (_commentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.commentViewModel.comments.isEmpty) {
      return _buildEmptyComments();
    }

    return _buildCommentsList();
  }

  Widget _buildEmptyComments() {
    return Card(
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
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => MediaAddComment(
                    mediaItemId: widget.mediaItemId,
                    onCommentAdded: (newComment) {
                      widget.commentViewModel.addComment(newComment);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: widget.commentViewModel.comments.map((comment) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(comment.userName),
                      child: Text(
                        comment.userName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${comment.date.day}/${comment.date.month}/${comment.date.year}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rating Stars
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          Icon(
                            i <= comment.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Comment Text
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => MediaEditComment(
                            comment: comment,
                            onCommentUpdated: (updatedComment) {
                              widget.commentViewModel.updateComment(updatedComment);
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => MediaDeleteComment(
                            comment: comment,
                            onCommentDeleted: () {
                              widget.commentViewModel.deleteComment(comment.id);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getAvatarColor(String userName) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final index = userName.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }
}