import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';

class MediaAddComment extends StatefulWidget {
  final String mediaItemId;
  final Function(MediaComment) onCommentAdded;

  const MediaAddComment({
    super.key,
    required this.mediaItemId,
    required this.onCommentAdded,
  });

  @override
  State<MediaAddComment> createState() => _MediaAddCommentState();
}

class _MediaAddCommentState extends State<MediaAddComment> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  double _rating = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.comment),
          SizedBox(width: 8),
          Text('Add Comment'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Name
            TextField(
              controller: _userNameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Rating
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = i.toDouble();
                      });
                    },
                  ),
              ],
            ),
            Text('${_rating.toInt()}/5', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // Comment Text
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Your Comment',
                border: OutlineInputBorder(),
                hintText: 'Share your thoughts about this media...',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addComment,
          child: const Text('Add Comment'),
        ),
      ],
    );
  }

  void _addComment() {
    if (_userNameController.text.isEmpty || _textController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and provide a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newComment = MediaComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mediaItemId: widget.mediaItemId,
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}', // Simple user ID
      userName: _userNameController.text,
      date: DateTime.now(),
      rating: _rating,
      text: _textController.text,
    );

    widget.onCommentAdded(newComment);
    Navigator.pop(context);
  }
}