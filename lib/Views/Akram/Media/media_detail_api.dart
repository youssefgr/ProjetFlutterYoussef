import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../viewmodels/Akram/media_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaDetailApi extends StatefulWidget {
  final dynamic item;
  final MediaViewModel? viewModel;

  const MediaDetailApi({
    super.key,
    required this.item,
    this.viewModel,
  });

  @override
  State<MediaDetailApi> createState() => _MediaDetailApiState();
}

class _MediaDetailApiState extends State<MediaDetailApi> {
  bool _isAdding = false;
  bool _isAlreadyInCollection = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyInCollection();
  }

  // Check if the item is already in the collection
  Future<void> _checkIfAlreadyInCollection() async {
    if (widget.viewModel == null) return;

    String title = '';
    if (widget.item is Movie) {
      title = (widget.item as Movie).title;
    } else if (widget.item is Series) {
      title = (widget.item as Series).name;
    } else if (widget.item is Anime) {
      title = (widget.item as Anime).title;
    } else if (widget.item is Manga) {
      title = (widget.item as Manga).title;
    }

    final existingItems = widget.viewModel!.mediaItems.where((item) =>
    item.title.toLowerCase() == title.toLowerCase()).toList();

    if (mounted) {
      setState(() {
        _isAlreadyInCollection = existingItems.isNotEmpty;
      });
    }
  }

  Future<void> _showAddToCollectionDialog() async {
    MediaCategory? selectedCategory;
    MediaViewStatus selectedStatus = MediaViewStatus.toView;
    MediaGenre selectedGenre = MediaGenre.action;

    // Pre-select category and genre based on item type
    if (widget.item is Movie) {
      selectedCategory = MediaCategory.film;
      final movie = widget.item as Movie;
      if (movie.genres.isNotEmpty) {
        selectedGenre = GenreMapper.autoDetectGenre(movie.genres);
      }
    } else if (widget.item is Series) {
      selectedCategory = MediaCategory.series;
      final series = widget.item as Series;
      if (series.genres.isNotEmpty) {
        selectedGenre = GenreMapper.autoDetectGenre(series.genres);
      }
    } else if (widget.item is Anime) {
      selectedCategory = MediaCategory.anime;
      final anime = widget.item as Anime;
      if (anime.genres.isNotEmpty) {
        selectedGenre = GenreMapper.autoDetectGenre(anime.genres);
      }
    } else if (widget.item is Manga) {
      selectedCategory = MediaCategory.manga; // Add manga category
      final manga = widget.item as Manga;
      if (manga.genres.isNotEmpty) {
        selectedGenre = GenreMapper.autoDetectGenre(manga.genres);
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add to Collection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MediaCategory.values.map((category) {
                    return ChoiceChip(
                      label: Text(GenreMapper.formatEnumName(category.name)),
                      selected: selectedCategory == category,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedCategory = selected ? category : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: MediaViewStatus.values.map((status) {
                    return ChoiceChip(
                      label: Text(GenreMapper.formatEnumName(status.name)),
                      selected: selectedStatus == status,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedStatus = status;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Genre',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MediaGenre.values.map((genre) {
                    return ChoiceChip(
                      label: Text(GenreMapper.formatEnumName(genre.name)),
                      selected: selectedGenre == genre,
                      onSelected: (selected) {
                        setDialogState(() {
                          selectedGenre = genre;
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCategory == null
                  ? null
                  : () => Navigator.pop(context, {
                'category': selectedCategory,
                'status': selectedStatus,
                'genre': selectedGenre,
              }),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _addToCollection(
        result['category'] as MediaCategory,
        result['status'] as MediaViewStatus,
        result['genre'] as MediaGenre,
      );
    }
  }

  Future<void> _addToCollection(
      MediaCategory category,
      MediaViewStatus status,
      MediaGenre genre,
      ) async {
    setState(() {
      _isAdding = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
      String title = '';
      String overview = '';
      String releaseDate = '';
      String imageUrl = '';

      if (widget.item is Movie) {
        final movie = widget.item as Movie;
        title = movie.title;
        overview = movie.overview;
        releaseDate = movie.releaseDate;
        imageUrl = movie.posterPath.isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
            : '';
      } else if (widget.item is Series) {
        final series = widget.item as Series;
        title = series.name;
        overview = series.overview;
        releaseDate = series.firstAirDate;
        imageUrl = series.posterPath.isNotEmpty
            ? 'https://image.tmdb.org/t/p/w500${series.posterPath}'
            : '';
      } else if (widget.item is Anime) {
        final anime = widget.item as Anime;
        title = anime.title;
        overview = anime.synopsis;
        releaseDate = anime.startDate.isNotEmpty ? anime.startDate : DateTime.now().toIso8601String();
        imageUrl = anime.posterPath;
      } else if (widget.item is Manga) {
        final manga = widget.item as Manga;
        title = manga.title;
        overview = manga.overview;
        releaseDate = manga.releaseDate.isNotEmpty ? manga.releaseDate : DateTime.now().toIso8601String();
        imageUrl = manga.posterPath;
      }

      final mediaItem = MediaItem(
        id: const Uuid().v4(),
        category: category,
        title: title,
        imageUrl: imageUrl,
        releaseDate: releaseDate.isNotEmpty
            ? DateTime.parse(releaseDate)
            : DateTime.now(),
        description: overview,
        status: status,
        genre: genre,
        userId: userId,
      );

      if (widget.viewModel != null) {
        await widget.viewModel!.addMediaItem(mediaItem);
        // Update the state after adding
        setState(() {
          _isAlreadyInCollection = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$title" to your collection!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to collection: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  void _showAlreadyInCollectionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('This item is already in your collection!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = '';
    String imageUrl = '';
    Color themeColor = Colors.blue;

    if (widget.item is Movie) {
      final movie = widget.item as Movie;
      title = movie.title;
      imageUrl = movie.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${movie.posterPath}'
          : '';
      themeColor = Colors.orange;
    } else if (widget.item is Series) {
      final series = widget.item as Series;
      title = series.name;
      imageUrl = series.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${series.posterPath}'
          : '';
      themeColor = Colors.blue;
    } else if (widget.item is Anime) {
      final anime = widget.item as Anime;
      title = anime.title;
      imageUrl = anime.posterPath;
      themeColor = Colors.purple;
    } else if (widget.item is Manga) {
      final manga = widget.item as Manga;
      title = manga.title;
      imageUrl = manga.posterPath;
      themeColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
        actions: [
          // Show different icon based on whether item is already in collection
          if (_isAlreadyInCollection)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              onPressed: _showAlreadyInCollectionMessage,
              tooltip: 'Already in Collection',
            )
          else
            IconButton(
              icon: _isAdding
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.add),
              onPressed: _isAdding ? null : _showAddToCollectionDialog,
              tooltip: 'Add to Collection',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            if (imageUrl.isNotEmpty)
              Hero(
                tag: 'media_${title}_image',
                child: Container(
                  height: 400,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: themeColor.withOpacity(0.2),
                        child: Icon(
                          widget.item is Manga ? Icons.menu_book_outlined : Icons.movie_outlined,
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
                  widget.item is Manga ? Icons.menu_book_outlined : Icons.movie_outlined,
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
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Build details based on type
                  if (widget.item is Movie) _buildMovieContent(widget.item as Movie, themeColor),
                  if (widget.item is Series) _buildSeriesContent(widget.item as Series, themeColor),
                  if (widget.item is Anime) _buildAnimeContent(widget.item as Anime, themeColor),
                  if (widget.item is Manga) _buildMangaContent(widget.item as Manga, themeColor), // UNCOMMENT THIS LINE
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieContent(Movie movie, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and Release Date
        Row(
          children: [
            if (movie.voteAverage > 0) ...[
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                movie.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Icon(Icons.calendar_today, color: themeColor, size: 20),
            const SizedBox(width: 4),
            Text(
              movie.releaseDate,
              style: const TextStyle(fontSize: 16),
            ),
            if (movie.runtime > 0) ...[
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: themeColor, size: 20),
              const SizedBox(width: 4),
              Text(
                '${movie.runtime} min',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Genres
        if (movie.genres.isNotEmpty) ...[
          _buildSectionTitle('Genres'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: movie.genres
                .map((genre) => Chip(
              label: Text(genre),
              backgroundColor: themeColor.withOpacity(0.2),
              labelStyle: TextStyle(color: themeColor),
            ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Overview
        _buildSectionTitle('Overview'),
        const SizedBox(height: 8),
        Text(
          movie.overview.isEmpty ? 'No overview available' : movie.overview,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Additional Details
        _buildSectionTitle('Additional Information'),
        const SizedBox(height: 12),
        _buildDetailRow('Language', movie.originalLanguage.toUpperCase(), themeColor),
        _buildDetailRow('Popularity', movie.popularity.toStringAsFixed(1), themeColor),
        _buildDetailRow('Vote Count', movie.voteCount.toString(), themeColor),
      ],
    );
  }

  Widget _buildMangaContent(Manga manga, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and Release Date
        Row(
          children: [
            if (manga.voteAverage > 0) ...[
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                manga.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Icon(Icons.calendar_today, color: themeColor, size: 20),
            const SizedBox(width: 4),
            Text(
              manga.releaseDate.isNotEmpty ? manga.releaseDate : 'Unknown',
              style: const TextStyle(fontSize: 16),
            ),
            if (manga.runtime > 0) ...[
              const SizedBox(width: 16),
              Icon(Icons.format_list_numbered, color: themeColor, size: 20),
              const SizedBox(width: 4),
              Text(
                '${manga.runtime} chapters',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Genres
        if (manga.genres.isNotEmpty) ...[
          _buildSectionTitle('Genres'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: manga.genres
                .map((genre) => Chip(
              label: Text(genre),
              backgroundColor: themeColor.withOpacity(0.2),
              labelStyle: TextStyle(color: themeColor),
            ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Overview
        _buildSectionTitle('Overview'),
        const SizedBox(height: 8),
        Text(
          manga.overview.isEmpty ? 'No overview available' : manga.overview,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSeriesContent(Series series, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and First Air Date
        Row(
          children: [
            if (series.voteAverage > 0) ...[
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                series.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Icon(Icons.calendar_today, color: themeColor, size: 20),
            const SizedBox(width: 4),
            Text(
              series.firstAirDate,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Genres
        if (series.genres.isNotEmpty) ...[
          _buildSectionTitle('Genres'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: series.genres
                .map((genre) => Chip(
              label: Text(genre),
              backgroundColor: themeColor.withOpacity(0.2),
              labelStyle: TextStyle(color: themeColor),
            ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Overview
        _buildSectionTitle('Overview'),
        const SizedBox(height: 8),
        Text(
          series.overview.isEmpty ? 'No overview available' : series.overview,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Additional Details
        _buildSectionTitle('Additional Information'),
        const SizedBox(height: 12),
        if (series.status.isNotEmpty)
          _buildDetailRow('Status', series.status, themeColor),
        if (series.numberOfSeasons > 0)
          _buildDetailRow('Seasons', series.numberOfSeasons.toString(), themeColor),
        if (series.numberOfEpisodes > 0)
          _buildDetailRow('Episodes', series.numberOfEpisodes.toString(), themeColor),
        _buildDetailRow('Language', series.originalLanguage.toUpperCase(), themeColor),
        _buildDetailRow('Popularity', series.popularity.toStringAsFixed(1), themeColor),
        _buildDetailRow('Vote Count', series.voteCount.toString(), themeColor),
      ],
    );
  }

  Widget _buildAnimeContent(Anime anime, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and Start Date
        Row(
          children: [
            if (anime.mean > 0) ...[
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 4),
              Text(
                anime.mean.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (anime.startDate.isNotEmpty) ...[
              Icon(Icons.calendar_today, color: themeColor, size: 20),
              const SizedBox(width: 4),
              Text(
                anime.startDate,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Ranking
        if (anime.ranking > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Ranking: #${anime.ranking}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Genres
        if (anime.genres.isNotEmpty) ...[
          _buildSectionTitle('Genres'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: anime.genres
                .map((genre) => Chip(
              label: Text(genre),
              backgroundColor: themeColor.withOpacity(0.2),
              labelStyle: TextStyle(color: themeColor),
            ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Synopsis
        _buildSectionTitle('Synopsis'),
        const SizedBox(height: 8),
        Text(
          anime.synopsis.isEmpty ? 'No synopsis available' : anime.synopsis,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Studios
        if (anime.studios.isNotEmpty) ...[
          _buildSectionTitle('Studios'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: anime.studios
                .map((studio) => Chip(
              label: Text(studio),
              backgroundColor: themeColor.withOpacity(0.2),
              labelStyle: TextStyle(color: themeColor),
            ))
                .toList(),
          ),
        ],
      ],
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
}