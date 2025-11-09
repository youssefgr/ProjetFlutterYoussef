import 'package:flutter/material.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../viewmodels/Akram/media_viewmodel.dart';
import 'media_views.dart';
import 'media_export_pdf.dart'; // Add this import


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
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMediaItems() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _viewModel.loadMediaItems();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _exportToPDF() async {
    if (_viewModel.mediaItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No media items to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await MediaExportPDF.exportMediaListToPDF(context, _viewModel);
  }
  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Media Collection'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
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
          // Add PDF Export Icon
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildSearchBar(theme, isDark),
          if (_viewModel.hasActiveFilters) _buildActiveFiltersIndicator(theme, isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMediaItems,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
          ),
        ],
      ),
    );
  }
  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: 'Search by title or description...',
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: theme.iconTheme.color),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersIndicator(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.blue[900] : Colors.blue[50],
      child: Row(
        children: [
          Expanded(
            child: Text(
              _viewModel.activeFiltersDescription,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.blue[200] : Colors.blue,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear, size: 16, color: isDark ? Colors.blue[200] : Colors.blue),
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
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$title | ${sectionItems.length}',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
            onTap: () async {
              await Navigator.push(
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
              // Reload data when returning from detail screen
              await _loadMediaItems();
            },
          ),
        );
      },
    );
  }
}

// Updated Filter Dialog Widget with Dark Theme
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
  MediaGenre? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.viewModel.selectedCategory;
    _selectedStatus = widget.viewModel.selectedStatus;
    _selectedGenre = widget.viewModel.selectedGenre;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt, color: theme.iconTheme.color),
                const SizedBox(width: 8),
                Text(
                  'Filter Media',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Section
            Text('Category', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: MediaCategory.values.map((category) {
                return FilterChip(
                  label: Text(
                    category.toString().split('.').last,
                    style: TextStyle(
                      color: _selectedCategory == category
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: _selectedCategory == category,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: theme.primaryColor,
                  checkmarkColor: theme.colorScheme.onPrimary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Status Section
            Text('Status', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: MediaViewStatus.values.map((status) {
                return FilterChip(
                  label: Text(
                    status.toString().split('.').last,
                    style: TextStyle(
                      color: _selectedStatus == status
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? status : null;
                    });
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: theme.primaryColor,
                  checkmarkColor: theme.colorScheme.onPrimary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Genre Section
            Text('Genre', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: MediaGenre.values.map((genre) {
                return FilterChip(
                  label: Text(
                    genre.toString().split('.').last,
                    style: TextStyle(
                      color: _selectedGenre == genre
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: _selectedGenre == genre,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGenre = selected ? genre : null;
                    });
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  selectedColor: theme.primaryColor,
                  checkmarkColor: theme.colorScheme.onPrimary,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedStatus = null;
                      _selectedGenre = null;
                    });
                  },
                  child: Text('Clear All', style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel', style: theme.textTheme.bodyMedium),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.viewModel.setCategoryFilter(_selectedCategory);
                    widget.viewModel.setStatusFilter(_selectedStatus);
                    widget.viewModel.setGenreFilter(_selectedGenre);
                    widget.onFiltersChanged();
                    Navigator.pop(context);
                  },
                  child: Text('Apply', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}