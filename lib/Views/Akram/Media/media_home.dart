import 'package:flutter/material.dart';
import '../../../viewmodels/Akram/media_viewmodel.dart';
import '../../../Models/Akram/movie_model.dart';
import '../../../Models/Akram/series_model.dart';
import '../../../Models/Akram/anime_model.dart';
import 'media_detail_api.dart';

class MediaHome extends StatefulWidget {
  const MediaHome({super.key});

  @override
  State<MediaHome> createState() => _MediaHomeState();
}

class _MediaHomeState extends State<MediaHome> {
  final MediaViewModel _viewModel = MediaViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.onMediaItemsUpdated = () {
      if (mounted) {
        setState(() {});
      }
    };
    _loadData();
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
    if (_viewModel.isLoadingAny &&
        _viewModel.movies.isEmpty &&
        _viewModel.series.isEmpty &&
        _viewModel.anime.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Collection'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHorizontalSection(
                _viewModel.movies,
                'Movies',
                Colors.orange,
                _viewModel.isLoadingMovies,
                _viewModel.moviesError,
              ),
              const SizedBox(height: 16),
              _buildHorizontalSection(
                _viewModel.series,
                'Series',
                Colors.blue,
                _viewModel.isLoadingSeries,
                _viewModel.seriesError,
              ),
              const SizedBox(height: 16),
              _buildHorizontalSection(
                _viewModel.anime,
                'Anime',
                Colors.purple,
                _viewModel.isLoadingAnime,
                _viewModel.animeError,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
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
          ],
        ),
      ),
    );
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
    String title = '';

    if (item is Movie) {
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
          : '';
      title = item.title;
    } else if (item is Series) {
      imageUrl = item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
          : '';
      title = item.name;
    } else if (item is Anime) {
      imageUrl = item.posterPath;
      title = item.title;
    }

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
                        Icons.movie_outlined,
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
                    Icons.movie_outlined,
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

  @override
  void dispose() {
    _viewModel.onMediaItemsUpdated = null;
    super.dispose();
  }
}