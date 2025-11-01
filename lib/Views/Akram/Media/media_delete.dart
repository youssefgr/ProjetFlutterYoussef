import 'dart:io';
import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../utils/image_utils.dart';

class MediaDelete extends StatelessWidget {
  final MediaItem mediaItem;
  final VoidCallback onDelete;

  const MediaDelete({
    super.key,
    required this.mediaItem,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Media'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${mediaItem.title}"?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (mediaItem.imageUrl.isNotEmpty) ...[
            FutureBuilder<File?>(
              future: ImageUtils.getImageFile(mediaItem.imageUrl),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'This action cannot be undone.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Delete the associated image file
            if (mediaItem.imageUrl.isNotEmpty) {
              await ImageUtils.deleteImage(mediaItem.imageUrl);
            }

            // Call the delete callback
            onDelete();

            // Close the delete dialog
            Navigator.pop(context);

            // Navigate back to MediaList (pop the MediaDetail screen)
            Navigator.pop(context);

            // Show success message on MediaList
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${mediaItem.title}" deleted successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}