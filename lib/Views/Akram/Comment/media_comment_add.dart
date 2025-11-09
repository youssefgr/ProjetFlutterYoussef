import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import '../../../Models/Akram/media_models.dart';

class MediaAddComment extends StatefulWidget {
  final String mediaItemId;
  final void Function(MediaComment) onCommentAdded;

  const MediaAddComment({super.key, required this.mediaItemId, required this.onCommentAdded});

  @override
  State<MediaAddComment> createState() => _MediaAddCommentState();
}

class _MediaAddCommentState extends State<MediaAddComment> {
  final _textController = TextEditingController();
  double _rating = 0.0;

  void _addComment() {
    if (_textController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rating and write a comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Wrap callback to avoid async assignment issues
    widget.onCommentAdded(
      MediaComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mediaItemId: widget.mediaItemId,
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Current User', // Replace with actual user from Supabase if available
        date: DateTime.now(),
        rating: _rating,
        text: _textController.text, mediaTitle: '',
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.comment), SizedBox(width: 8), Text('Add Comment')]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
          StarRating(
            size: 40,
            rating: _rating,
            color: Colors.amber,
            borderColor: Colors.grey,
            starCount: 5,
            onRatingChanged: (rating) => setState(() => _rating = rating),
          ),
          Text('${_rating.toStringAsFixed(1)}/5', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Your Comment',
              border: OutlineInputBorder(),
              hintText: 'Share your thoughts...',
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _addComment, child: const Text('Add Comment')),
      ],
    );
  }
}
