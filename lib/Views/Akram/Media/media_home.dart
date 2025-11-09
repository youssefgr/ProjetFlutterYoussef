import 'package:flutter/material.dart';
import '../../../viewmodels/Akram/media_viewmodel.dart';
import '../../../Models/Akram/media_models.dart';
import 'media_detail_api.dart';
import 'media_news.dart';


class MediaHome extends StatefulWidget {
  const MediaHome({super.key});

  @override
  State<MediaHome> createState() => _MediaHomeState();
}

class _MediaHomeState extends State<MediaHome> {
  final MediaViewModel _viewModel = MediaViewModel();
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _viewModel.onMediaItemsUpdated = () {
      if (mounted) {
        setState(() {});
      }
    };
    _loadData();

    _searchController.addListener(() {
      _viewModel.setApiSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _viewModel.loadAllMedia();
  }

  void _navigateToDetail(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailApi(
          item: item,
          viewModel: _viewModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_viewModel.isLoadingAny &&
        _viewModel.filteredMovies.isEmpty &&
        _viewModel.filteredSeries.isEmpty &&
        _viewModel.filteredAnime.isEmpty &&
        _viewModel.filteredManga.isEmpty) {
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
                if (_viewModel.hasActiveApiFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
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
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildSearchBar(theme, isDark),
          if (_viewModel.hasActiveApiFilters) _buildActiveFiltersIndicator(theme, isDark),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    MediaNews(viewModel: _viewModel),


                    const SizedBox(height: 16),
                    _buildHorizontalSection(
                      _viewModel.filteredMovies,
                      'Movies',
                      Colors.orange,
                      _viewModel.isLoadingMovies,
                      _viewModel.moviesError,
                    ),
                    const SizedBox(height: 16),
                    _buildHorizontalSection(
                      _viewModel.filteredSeries,
                      'Series',
                      Colors.blue,
                      _viewModel.isLoadingSeries,
                      _viewModel.seriesError,
                    ),
                    const SizedBox(height: 16),
                    _buildHorizontalSection(
                      _viewModel.filteredAnime,
                      'Anime',
                      Colors.purple,
                      _viewModel.isLoadingAnime,
                      _viewModel.animeError,
                    ),
                    const SizedBox(height: 16),
                    _buildHorizontalSection(
                      _viewModel.filteredManga,
                      'Manga',
                      Colors.green,
                      _viewModel.isLoadingManga,
                      _viewModel.mangaError,
                    ),
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
          hintText: 'Search by title...',
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
              _viewModel.activeApiFiltersDescription,
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
              _viewModel.clearAllApiFilters();
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
      builder: (context) => ApiFilterDialog(
        viewModel: _viewModel,
        onFiltersChanged: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildHorizontalSection(
      List<dynamic> items,
      String title,
      Color color,
      bool isLoading,
      String? error,
      ) {
    if (_viewModel.hasActiveApiFilters && items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '$title | ${items.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 180,
          child: items.isEmpty
              ? _buildEmptySection(title, color, isLoading)
              : _buildHorizontalScrollView(items, color),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String title, Color color, bool isLoading) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: CircularProgressIndicator(color: color),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getSectionIcon(title),
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
            if (_viewModel.hasActiveApiFilters)
              Text(
                'Try changing your filters',
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

  IconData _getSectionIcon(String title) {
    switch (title.toLowerCase()) {
      case 'manga':
        return Icons.menu_book_outlined;
      default:
        return Icons.movie_outlined;
    }
  }

  Widget _buildHorizontalScrollView(List<dynamic> items, Color color) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: 120,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildMediaCard(item, color),
        );
      },
    );
  }

  Widget _buildMediaCard(dynamic item, Color color) {
    String imageUrl = '';

    if (item is Movie) {
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
          : '';
    } else if (item is Series) {
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
          : '';
    } else if (item is Anime) {
      imageUrl = item.posterPath;
    } else if (item is Manga) {
      imageUrl = item.posterPath;
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Theme.of(context).cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: color.withOpacity(0.2),
                      child: Icon(
                        _getItemIcon(item),
                        color: color,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: color.withOpacity(0.1),
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
                )
                    : Container(
                  color: color.withOpacity(0.2),
                  child: Icon(
                    _getItemIcon(item),
                    color: color,
                    size: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(dynamic item) {
    if (item is Manga) {
      return Icons.menu_book_outlined;
    }
    return Icons.movie_outlined;
  }
}

class ApiFilterDialog extends StatefulWidget {
  final MediaViewModel viewModel;
  final VoidCallback onFiltersChanged;

  const ApiFilterDialog({
    super.key,
    required this.viewModel,
    required this.onFiltersChanged,
  });

  @override
  State<ApiFilterDialog> createState() => _ApiFilterDialogState();
}

class _ApiFilterDialogState extends State<ApiFilterDialog> {
  MediaCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.viewModel.selectedApiCategory;
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
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
                    widget.viewModel.setApiCategoryFilter(_selectedCategory);
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