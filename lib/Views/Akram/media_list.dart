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
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _viewModel.onMediaItemsUpdated = _onMediaItemsUpdated;
    _loadMediaItems();

    _searchController.addListener(() {
      _viewModel.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
                if (!_showFilters) {
                  _searchController.clear();
                }
              });
            },
          ),
          // Filter Icon
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_alt),
                if (_viewModel.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
          ),
          // Add Icon
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
      body: Column(
        children: [
          // Search Bar
          if (_showFilters) _buildSearchBar(),
          // Active Filters Indicator
          if (_viewModel.hasActiveFilters) _buildActiveFiltersIndicator(),
          // Media Sections
          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title or description...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          Expanded(
            child: Text(
              _viewModel.activeFiltersDescription,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              _viewModel.clearAllFilters();
              _searchController.clear();
            },
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        viewModel: _viewModel,
        onFiltersChanged: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildHorizontalSection(MediaViewStatus status, String title, Color color) {
    final sectionItems = _viewModel.getItemsByStatus(status);

    if (sectionItems.isEmpty && _viewModel.hasActiveFilters) {
      return const SizedBox.shrink(); // Hide empty sections when filtering
    }

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
            if (_viewModel.hasActiveFilters)
              Text(
                'Try changing your filters',
                style: TextStyle(
                  color: color.withOpacity(0.5),
                  fontSize: 12,
                ),
              )
            else
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

// Filter Dialog Widget
// Filter Dialog Widget
class FilterDialog extends StatefulWidget {
  final MediaViewModel viewModel;
  final VoidCallback onFiltersChanged;

  const FilterDialog({
    super.key,
    required this.viewModel,
    required this.onFiltersChanged,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  MediaCategory? _selectedCategory;
  MediaViewStatus? _selectedStatus;
  List<MediaGenre> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    // Initialize with current filter states using getters
    _selectedCategory = widget.viewModel.selectedCategory;
    _selectedStatus = widget.viewModel.selectedStatus;
    _selectedGenres = List.from(widget.viewModel.selectedGenres);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.filter_alt),
          SizedBox(width: 8),
          Text('Filter Media'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: MediaCategory.values.map((category) {
                return FilterChip(
                  label: Text(category.toString().split('.').last),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Status Filter
            const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: MediaViewStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.toString().split('.').last),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Genre Filter
            const Text('Genres', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: MediaGenre.values.map((genre) {
                return FilterChip(
                  label: Text(genre.toString().split('.').last),
                  selected: _selectedGenres.contains(genre),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Clear all filters
            setState(() {
              _selectedCategory = null;
              _selectedStatus = null;
              _selectedGenres.clear();
            });
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Apply filters using public methods
            widget.viewModel.setCategoryFilter(_selectedCategory);
            widget.viewModel.setStatusFilter(_selectedStatus);

            // Update genre filters
            final currentGenres = widget.viewModel.selectedGenres;

            // Remove genres that are no longer selected
            for (final genre in currentGenres) {
              if (!_selectedGenres.contains(genre)) {
                widget.viewModel.toggleGenreFilter(genre);
              }
            }

            // Add newly selected genres
            for (final genre in _selectedGenres) {
              if (!currentGenres.contains(genre)) {
                widget.viewModel.toggleGenreFilter(genre);
              }
            }

            widget.onFiltersChanged();
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
