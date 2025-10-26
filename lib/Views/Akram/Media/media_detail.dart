import 'dart:io';
import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../utils/image_utils.dart';
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
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaEdit(mediaItem: widget.mediaItem),
                ),
              ).then((updatedItem) {
                if (updatedItem != null && widget.onUpdate != null) {
                  widget.onUpdate!(updatedItem);
                  Navigator.pop(context, updatedItem);
                }
              });
            },
          ),
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
            _buildPosterImage(),
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

            // Category and Status
            Row(
              children: [
                _buildInfoChip(
                  'Category',
                  widget.mediaItem.category.toString().split('.').last,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Status',
                  widget.mediaItem.status.toString().split('.').last,
                  _getStatusColor(widget.mediaItem.status),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Release Date
            _buildInfoRow('Release Date',
                '${widget.mediaItem.releaseDate.day}/${widget.mediaItem.releaseDate.month}/${widget.mediaItem.releaseDate.year}'),
            const SizedBox(height: 16),

            // Genres
            _buildInfoRow('Genres',
                widget.mediaItem.genres.map((g) => g.toString().split('.').last).join(', ')),
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
              widget.mediaItem.description.isEmpty ? 'No description available' : widget.mediaItem.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Comments Section (Separated Component)
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

  Widget _buildPosterImage() {
    if (widget.mediaItem.imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<File?>(
      future: ImageUtils.getImageFile(widget.mediaItem.imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading image...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                snapshot.data!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        return Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 80, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Image not found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      },
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