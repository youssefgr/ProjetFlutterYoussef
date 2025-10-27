import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Akram/media_models.dart';
import 'package:projetflutteryoussef/viewmodels/media_viewmodel.dart';
import 'media_add.dart';
import 'media_detail.dart';
import 'media_grid_item.dart';

class MediaList extends StatefulWidget {
  const MediaList({super.key});

  @override
  State<MediaList> createState() => _MediaListState();
}

class _MediaListState extends State<MediaList> {
  final MediaViewModel _viewModel = MediaViewModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewModel.onMediaItemsUpdated = _onMediaItemsUpdated;
    _loadMediaItems();
  }

  void _onMediaItemsUpdated() {
    setState(() {});
  }

  Future<void> _loadMediaItems() async {
    setState(() {
      _isLoading = true;
    });
    await _viewModel.loadMediaItems();
    setState(() {
      _isLoading = false;
    });
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
                  _viewModel.addMediaItem(newItem);
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHorizontalSection(MediaViewStatus.toView, 'To View', Colors.orange),
            const SizedBox(height: 16),
            _buildHorizontalSection(MediaViewStatus.viewing, 'Viewing', Colors.blue),
            const SizedBox(height: 16),
            _buildHorizontalSection(MediaViewStatus.viewed, 'Viewed', Colors.green),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(MediaViewStatus status, String title, Color color) {
    final sectionItems = _viewModel.getItemsByStatus(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$title (${sectionItems.length})',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Horizontal Scrollable Row with Drag Target
        Container(
          height: 180,
          child: DragTarget<MediaItem>(
            onAccept: (draggedItem) {
              _viewModel.updateMediaStatus(draggedItem.id, status);
            },
            builder: (context, candidateData, rejectedData) {
              return Container(
                color: candidateData.isNotEmpty ? color.withOpacity(0.1) : Colors.transparent,
                child: sectionItems.isEmpty
                    ? _buildEmptySection(title, color)
                    : _buildHorizontalScrollView(sectionItems, color),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
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
              'No items in $title',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            Text(
              'Drag items here to add',
              style: TextStyle(
                color: color.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalScrollView(List<MediaItem> items, Color color) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: 120,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: MediaGridItem(
            item: item,
            sectionColor: color,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaDetail(
                    mediaItem: item,
                    onUpdate: (updatedItem) {
                      _viewModel.updateMediaItem(updatedItem);
                    },
                    onDelete: (id) {
                      _viewModel.deleteMediaItem(id);
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}