import 'dart:io';
import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../viewmodels/Akram/media_comment_viewmodel.dart';
import '../Comment/media_comment_views.dart';
import 'media_views.dart';

class MediaDetail extends StatefulWidget {
  final MediaItem mediaItem;
  final Function(MediaItem)? onUpdate;
  final Function(String)? onDelete;

  const MediaDetail({
    super.key,
    required this.mediaItem,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<MediaDetail> createState() => _MediaDetailState();
}

class _MediaDetailState extends State<MediaDetail> {
  final CommentViewModel _commentViewModel = CommentViewModel();

  @override
  void initState() {
    super.initState();
    _commentViewModel.loadCommentsForMedia(widget.mediaItem.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mediaItem.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => MediaDelete(
                  mediaItem: widget.mediaItem,
                  onDelete: () {
                    if (widget.onDelete != null) {
                      widget.onDelete!(widget.mediaItem.id);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            const SizedBox(height: 24),

            // Title
            Text(
              widget.mediaItem.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category, Status, and Genre chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  'Category',
                  widget.mediaItem.category.toString().split('.').last,
                  Colors.blue,
                ),
                _buildInfoChip(
                  'Status',
                  widget.mediaItem.status.toString().split('.').last,
                  _getStatusColor(widget.mediaItem.status),
                ),
                _buildInfoChip(
                  'Genre',
                  widget.mediaItem.genre.toString().split('.').last,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Release Date
            _buildInfoRow(
              'Release Date',
              '${widget.mediaItem.releaseDate.day}/${widget.mediaItem.releaseDate.month}/${widget.mediaItem.releaseDate.year}',
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mediaItem.description.isEmpty
                  ? 'No description available'
                  : widget.mediaItem.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Comments Section
            MediaCommentDetail(
              mediaItemId: widget.mediaItem.id,
              mediaTitle: widget.mediaItem.title,
              commentViewModel: _commentViewModel,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoChip(String label, String value, Color color) {
    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Color _getStatusColor(MediaViewStatus status) {
    switch (status) {
      case MediaViewStatus.toView:
        return Colors.orange;
      case MediaViewStatus.viewing:
        return Colors.blue;
      case MediaViewStatus.viewed:
        return Colors.green;
    }
  }
}