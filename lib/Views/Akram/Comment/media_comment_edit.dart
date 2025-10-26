import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';

class MediaEditComment extends StatefulWidget {
  final MediaComment comment;
  final Function(MediaComment) onCommentUpdated;

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
  late TextEditingController _userNameController;
  late double _rating;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.comment.text);
    _userNameController = TextEditingController(text: widget.comment.userName);
    _rating = widget.comment.rating;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit),
          SizedBox(width: 8),
          Text('Edit Comment'),
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
          onPressed: _updateComment,
          child: const Text('Update Comment'),
        ),
      ],
    );
  }

  void _updateComment() {
    if (_userNameController.text.isEmpty || _textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedComment = widget.comment.copyWith(
      userName: _userNameController.text,
      rating: _rating,
      text: _textController.text,
      date: DateTime.now(),
    );

    widget.onCommentUpdated(updatedComment);
    Navigator.pop(context);
  }
}