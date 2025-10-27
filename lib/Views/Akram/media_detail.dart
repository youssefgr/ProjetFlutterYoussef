import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Akram/media_models.dart';
import '../../utils/image_utils.dart';
import 'media_edit.dart';
import 'media_delete.dart';

class MediaDetail extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mediaItem.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaEdit(mediaItem: mediaItem),
                ),
              ).then((updatedItem) {
                if (updatedItem != null) {
                  if (onUpdate != null) {
                    onUpdate!(updatedItem);
                  }
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
                  mediaItem: mediaItem,
                  onDelete: () {
                    if (onDelete != null) {
                      onDelete!(mediaItem.id);
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
            // Poster Image - expands to full width
            _buildPosterImage(),
            const SizedBox(height: 24),

            // Title
            Text(
              mediaItem.title,
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
                  mediaItem.category.toString().split('.').last,
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Status',
                  mediaItem.status.toString().split('.').last,
                  _getStatusColor(mediaItem.status),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Release Date
            _buildInfoRow('Release Date',
                '${mediaItem.releaseDate.day}/${mediaItem.releaseDate.month}/${mediaItem.releaseDate.year}'),
            const SizedBox(height: 16),

            // Genres
            _buildInfoRow('Genres',
                mediaItem.genres.map((g) => g.toString().split('.').last).join(', ')),
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
              mediaItem.description.isEmpty ? 'No description available' : mediaItem.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterImage() {
    if (mediaItem.posterUrl.isEmpty) {
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
      future: ImageUtils.getImageFile(mediaItem.posterUrl),
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