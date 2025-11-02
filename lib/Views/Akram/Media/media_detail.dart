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

  Color _getThemeColor() {
    switch (widget.mediaItem.category) {
      case MediaCategory.film:
        return Colors.orange;
      case MediaCategory.series:
        return Colors.blue;
      case MediaCategory.anime:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mediaItem.title),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image - Matching MediaDetailApi design
            if (widget.mediaItem.imageUrl.isNotEmpty)
              Hero(
                tag: 'media_${widget.mediaItem.id}_image',
                child: Container(
                  height: 400,
                  width: double.infinity,
                  child: Image.network(
                    widget.mediaItem.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: themeColor.withOpacity(0.2),
                        child: Icon(
                          Icons.movie_outlined,
                          color: themeColor,
                          size: 100,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 400,
                width: double.infinity,
                color: themeColor.withOpacity(0.2),
                child: Icon(
                  Icons.movie_outlined,
                  color: themeColor,
                  size: 100,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.mediaItem.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status, Category, and Genre chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(widget.mediaItem.status),
                      _buildCategoryChip(widget.mediaItem.category, themeColor),
                      _buildGenreChip(widget.mediaItem.genre, themeColor),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Release Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.mediaItem.releaseDate.day}/${widget.mediaItem.releaseDate.month}/${widget.mediaItem.releaseDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description/Overview
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    widget.mediaItem.description.isEmpty
                        ? 'No description available'
                        : widget.mediaItem.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  /*// Additional Information
                  _buildSectionTitle('Additional Information'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Category',
                      _formatEnumName(widget.mediaItem.category.name),
                      themeColor
                  ),
                  _buildDetailRow('Status',
                      _formatEnumName(widget.mediaItem.status.name),
                      themeColor
                  ),
                  _buildDetailRow('Genre',
                      _formatEnumName(widget.mediaItem.genre.name),
                      themeColor
                  ),
                  const SizedBox(height: 24),*/

                  // Comments Section
                  MediaCommentDetail(
                    mediaItemId: widget.mediaItem.id,
                    mediaTitle: widget.mediaItem.title,
                    commentViewModel: _commentViewModel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(MediaViewStatus status) {
    Color statusColor;
    switch (status) {
      case MediaViewStatus.toView:
        statusColor = Colors.orange;
      case MediaViewStatus.viewing:
        statusColor = Colors.blue;
      case MediaViewStatus.viewed:
        statusColor = Colors.green;
    }

    return Chip(
      label: Text(
        _formatEnumName(status.name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: statusColor,
    );
  }

  Widget _buildCategoryChip(MediaCategory category, Color themeColor) {
    return Chip(
      label: Text(
        _formatEnumName(category.name),
        style: TextStyle(
          color: themeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: themeColor.withOpacity(0.2),
    );
  }

  Widget _buildGenreChip(MediaGenre genre, Color themeColor) {
    return Chip(
      label: Text(
        _formatEnumName(genre.name),
        style: TextStyle(
          color: themeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: themeColor.withOpacity(0.2),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEnumName(String enumName) {
    return enumName.replaceAllMapped(
      RegExp(r'^[a-z]|[A-Z]'),
          (Match m) => m[0] == m[0]!.toLowerCase()
          ? m[0]!.toUpperCase()
          : ' ${m[0]}',
    ).trim();
  }
}