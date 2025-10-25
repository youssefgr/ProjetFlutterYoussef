import 'dart:io';

import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Entities/Akram/media_entities.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'package:projetflutteryoussef/repositories/media_repository.dart';
import 'media_add.dart';
import 'media_edit.dart';
import 'media_detail.dart';
import 'media_delete.dart';

class MediaList extends StatefulWidget {
  const MediaList({super.key});

  @override
  State<MediaList> createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  List<MediaItem> mediaItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMediaItems();
  }

  // Load media items from storage
  Future<void> _loadMediaItems() async {
    setState(() {
      _isLoading = true;
    });

    final items = await MediaRepository.loadMediaItems();
    setState(() {
      mediaItems = items;
      _isLoading = false;
    });
  }

  // Save media items to storage
  Future<void> _saveMediaItems() async {
    await MediaRepository.saveMediaItems(mediaItems);
  }

  // Add a new media item
  void _addMediaItem(MediaItem newItem) {
    setState(() {
      mediaItems.add(newItem);
    });
    _saveMediaItems();
  }

  // Update an existing media item
  void _updateMediaItem(MediaItem updatedItem) {
    setState(() {
      final index = mediaItems.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        mediaItems[index] = updatedItem;
      }
    });
    _saveMediaItems();
  }

  // Delete a media item
  void _deleteMediaItem(String id) {
    setState(() {
      mediaItems.removeWhere((item) => item.id == id);
    });
    _saveMediaItems();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MediaAdd()),
              ).then((newItem) {
                if (newItem != null) {
                  _addMediaItem(newItem);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusSection(MediaViewStatus.toView, 'To View', Colors.orange),
          _buildStatusSection(MediaViewStatus.viewing, 'Viewing', Colors.blue),
          _buildStatusSection(MediaViewStatus.viewed, 'Viewed', Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatusSection(MediaViewStatus status, String title, Color color) {
    final sectionItems = mediaItems.where((item) => item.status == status).toList();

    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(8),
        color: color.withOpacity(0.1),
        child: Column(
          children: [
            // Section Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Text(
                '$title (${sectionItems.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Drag Target Area
            Expanded(
              child: DragTarget<MediaItem>(
                onAccept: (draggedItem) {
                  final updatedItem = draggedItem.copyWith(status: status);
                  _updateMediaItem(updatedItem);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    child: sectionItems.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            size: 50,
                            color: color.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No items',
                            style: TextStyle(
                              color: color.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: sectionItems.length,
                      itemBuilder: (context, index) {
                        final item = sectionItems[index];
                        return Draggable<MediaItem>(
                          data: item,
                          feedback: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildItemImage(item, color, 30),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      _truncateTitle(item.title, 10),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MediaDetail(
                                    mediaItem: item,
                                    onUpdate: _updateMediaItem,
                                    onDelete: _deleteMediaItem,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildItemImage(item, color, 40),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      _truncateTitle(item.title, 12),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.category.toString().split('.').last,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.status.toString().split('.').last,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(MediaItem item, Color color, double size) {
    return FutureBuilder<File?>(
      future: ImageUtils.getImageFile(item.posterUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[100],
            ),
            child: Icon(Icons.movie, size: size * 0.6, color: color),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                snapshot.data!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          );
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[100],
          ),
          child: Icon(Icons.movie, size: size * 0.6, color: color),
        );
      },
    );
  }

  String _truncateTitle(String title, int maxLength) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }
}