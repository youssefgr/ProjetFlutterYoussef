import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';

class MediaEditComment extends StatefulWidget {
  final MediaComment comment;
  final void Function(MediaComment) onCommentUpdated;

  const MediaEditComment({
    super.key,
    required this.comment,
    required this.onCommentUpdated,
  });

  @override
  State<MediaEditComment> createState() => _MediaEditCommentState();
}

class _MediaEditCommentState extends State<MediaEditComment> {
  late TextEditingController _textController;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.comment.text);
    _rating = widget.comment.rating;
  }

  void _updateComment() {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedComment = widget.comment.copyWith(
      text: _textController.text,
      rating: _rating,
      date: DateTime.now(),
    );

    // Call the synchronous wrapper
    widget.onCommentUpdated(updatedComment);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit Comment')],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (i) => IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
                onPressed: () => setState(() => _rating = i + 1.0),
              ),
            ),
          ),
          Text('${_rating.toInt()}/5', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Your Comment',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _updateComment, child: const Text('Update Comment')),
      ],
    );
  }
}
