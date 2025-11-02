import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import '../../../Models/Akram/media_models.dart';

class MediaAddComment extends StatefulWidget {
  final String mediaItemId;
  final Function(MediaComment) onCommentAdded;

  const MediaAddComment({super.key, required this.mediaItemId, required this.onCommentAdded});

  @override
  State<MediaAddComment> createState() => _MediaAddCommentState();
}

class _MediaAddCommentState extends State<MediaAddComment> {
  final _textController = TextEditingController();
  final _userNameController = TextEditingController();
  double _rating = 0.0;

  void _addComment() {
    if (_userNameController.text.isEmpty || _textController.text.isEmpty || _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and provide a rating'), backgroundColor: Colors.red),
      );
      return;
    }

    widget.onCommentAdded(MediaComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mediaItemId: widget.mediaItemId,
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      userName: _userNameController.text,
      date: DateTime.now(),
      rating: _rating,
      text: _textController.text,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [Icon(Icons.comment), SizedBox(width: 8), Text('Add Comment')]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _userNameController,
            decoration: const InputDecoration(labelText: 'Your Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
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