import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';

class MediaGridItem extends StatefulWidget {
  final MediaItem item;
  final Color sectionColor;
  final VoidCallback onTap;

  const MediaGridItem({
    super.key,
    required this.item,
    required this.sectionColor,
    required this.onTap,
  });

  @override
  State<MediaGridItem> createState() => _MediaGridItemState();
}

class _MediaGridItemState extends State<MediaGridItem> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<MediaItem>(
      data: widget.item,
      feedback: _buildDragFeedback(),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragCompleted: () {
        setState(() {
          _isDragging = false;
        });
      },
      childWhenDragging: _buildPlaceholder(),
      child: _buildGridItem(),
    );
  }

  Widget _buildDragFeedback() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.sectionColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageContent(100, 140),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Opacity(
      opacity: 0.3,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildGridItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: _isDragging ? 0.5 : 1.0,
          child: Container(
            width: 120,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageContent(120, 160),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent(double width, double height) {
    if (widget.item.imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(
          Icons.movie_outlined,
          color: widget.sectionColor.withOpacity(0.5),
          size: 30,
        ),
      );
    }

    return Image.network(
      widget.item.imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover, // This ensures the image fills the container
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Icon(
            Icons.broken_image,
            color: widget.sectionColor.withOpacity(0.5),
            size: 30,
          ),
        );
      },
    );
  }

  String _truncateTitle(String title, int maxLength) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }
}