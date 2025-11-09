import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../viewmodels/Akram/media_viewmodel.dart';
import '../../../Models/Akram/media_models.dart';
import 'media_detail_api.dart';

class MediaNews extends StatefulWidget {
  final MediaViewModel viewModel;

  const MediaNews({super.key, required this.viewModel});

  @override
  State<MediaNews> createState() => _MediaNewsState();
}

class _MediaNewsState extends State<MediaNews> {
  int _currentIndex = 0;
  List<dynamic> _topRatedMedia = [];
  bool _isLoading = true;
  String? _error;

  // API Keys - use your existing keys from MediaViewModel
  static const String _tmdbApiKey = 'e30a8bbae804539701776e9413710ee0';
  static const String _malClientId = 'fa38936ac71c9615ff9e37646443b609';

  @override
  void initState() {
    super.initState();
    _loadTopRatedMedia();
  }

  Future<void> _loadTopRatedMedia() async {
    try {
      _isLoading = true;
      setState(() {});

      // Fetch top rated from all APIs in parallel with timeout
      final results = await Future.wait([
        _fetchTopRatedMovies(),
        _fetchTopRatedSeries(),
        _fetchTopRatedAnime(),
        _fetchTopRatedManga(),
      ], eagerError: false).catchError((e) {
        print('Error in parallel fetch: $e');
        return [ [], [], [], [] ]; // Return empty arrays if any fail
      });

      // Combine all results and ensure we have exactly 12 items
      List<dynamic> allTopRatedMedia = [];

      // Add items from each category, ensuring we get exactly 3 from each
      for (int i = 0; i < results.length; i++) {
        final categoryResults = results[i];
        if (categoryResults.length >= 3) {
          allTopRatedMedia.addAll(categoryResults.take(3));
        } else {
          // If we don't have enough items, log it and add what we have
          print('Category $i only returned ${categoryResults.length} items');
          allTopRatedMedia.addAll(categoryResults);
        }
      }

      print('Total items loaded: ${allTopRatedMedia.length}'); // Debug print

      setState(() {
        _topRatedMedia = allTopRatedMedia;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadTopRatedMedia: $e');
      setState(() {
        _error = 'Failed to load top rated media: $e';
        _isLoading = false;
      });
    }
  }
  // Fetch top rated movies from TMDB for current year
  Future<List<Movie>> _fetchTopRatedMovies() async {
    try {
      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse(
            'https://api.themoviedb.org/3/discover/movie?'
                'api_key=$_tmdbApiKey&'
                'sort_by=vote_average.desc&' // Sort by rating
                'primary_release_year=$currentYear&'
                'vote_count.gte=100&' // Only include movies with sufficient votes
                'page=1'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.take(3).map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching top rated movies: $e');
    }
    return [];
  }

  // Fetch top rated series from TMDB for current year
  Future<List<Series>> _fetchTopRatedSeries() async {
    try {
      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse(
            'https://api.themoviedb.org/3/discover/tv?'
                'api_key=$_tmdbApiKey&'
                'sort_by=vote_average.desc&' // Sort by rating
                'first_air_date_year=$currentYear&'
                'vote_count.gte=50&' // Only include series with sufficient votes
                'page=1'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.take(3).map((json) => Series.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching top rated series: $e');
    }
    return [];
  }

  // Fetch top rated anime from MyAnimeList for current year
  Future<List<Anime>> _fetchTopRatedAnime() async {
    try {
      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse(
            'https://api.myanimelist.net/v2/anime/ranking?'
                'ranking_type=all&' // Overall ranking (by score)
                'limit=10&' // Get more to filter by year
                'fields=id,title,main_picture,synopsis,mean,start_date,genres,rank'
        ),
        headers: {
          'X-MAL-CLIENT-ID': _malClientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'];

        // Filter anime from current year and take top 3 by rank
        final currentYearAnime = results
            .where((item) {
          final startDate = item['node']['start_date']?.toString() ?? '';
          return startDate.contains(currentYear.toString());
        })
            .take(3)
            .map((json) => Anime.fromJson(json))
            .toList();

        return currentYearAnime;
      }
    } catch (e) {
      print('Error fetching top rated anime: $e');
    }
    return [];
  }

  // Fetch top rated manga from MyAnimeList for current year
  Future<List<Manga>> _fetchTopRatedManga() async {
    try {
      final currentYear = DateTime.now().year;
      final response = await http.get(
        Uri.parse(
            'https://api.myanimelist.net/v2/manga/ranking?'
                'ranking_type=all&' // Overall ranking (by score)
                'limit=10&' // Get more to filter by year
                'fields=id,title,main_picture,synopsis,mean,start_date,genres,rank,authors'
        ),
        headers: {
          'X-MAL-CLIENT-ID': _malClientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'];

        // Filter manga from current year and take top 3 by rank
        final currentYearManga = results
            .where((item) {
          final startDate = item['node']['start_date']?.toString() ?? '';
          return startDate.contains(currentYear.toString());
        })
            .take(3)
            .map((json) => Manga.fromJson(json))
            .toList();

        return currentYearManga;
      }
    } catch (e) {
      print('Error fetching top rated manga: $e');
    }
    return [];
  }

  void _navigateToDetail(dynamic item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailApi(
          item: item,
          viewModel: widget.viewModel,
        ),
      ),
    );
  }

  String _getImageUrl(dynamic item) {
    if (item is Movie) {
      return item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
          : '';
    } else if (item is Series) {
      return item.posterPath.isNotEmpty
          ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
          : '';
    } else if (item is Anime) {
      return item.posterPath;
    } else if (item is Manga) {
      return item.posterPath;
    }
    return '';
  }

  Color _getMediaColor(dynamic item) {
    if (item is Movie) return Colors.orange;
    if (item is Series) return Colors.blue;
    if (item is Anime) return Colors.purple;
    if (item is Manga) return Colors.green; // ADDED MANGA COLOR
    return Colors.grey;
  }

  IconData _getMediaIcon(dynamic item) {
    if (item is Movie) return Icons.movie;
    if (item is Series) return Icons.tv;
    if (item is Anime) return Icons.animation;
    if (item is Manga) return Icons.menu_book; // ADDED MANGA ICON
    return Icons.help;
  }

  String _getMediaType(dynamic item) {
    if (item is Movie) return 'Movie';
    if (item is Series) return 'Series';
    if (item is Anime) return 'Anime';
    if (item is Manga) return 'Manga'; // ADDED MANGA TYPE
    return 'Media';
  }

  String _getRatingInfo(dynamic item) {
    if (item is Movie) {
      return '⭐ ${item.voteAverage.toStringAsFixed(1)}';
    } else if (item is Series) {
      return '⭐ ${item.voteAverage.toStringAsFixed(1)}';
    } else if (item is Anime) {
      return '⭐ ${item.mean.toStringAsFixed(1)}';
    } else if (item is Manga) {
      return '⭐ ${item.voteAverage.toStringAsFixed(1)}'; // Using voteAverage for manga
    }
    return '';
  }

  String _getItemTitle(dynamic item) {
    if (item is Movie) return item.title;
    if (item is Series) return item.name;
    if (item is Anime) return item.title;
    if (item is Manga) return item.title;
    return 'Unknown Title';
  }

  int _getCategoryIndex(dynamic item, int globalIndex) {
    if (item is Movie) return globalIndex % 3;
    if (item is Series) return globalIndex % 3;
    if (item is Anime) return globalIndex % 3;
    if (item is Manga) return globalIndex % 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        height: 200,
        child: Center(
          child: Text(
            _error!,
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_topRatedMedia.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '🔥 Top Rated This Year',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CarouselSlider(
          options: CarouselOptions(
            height: 220,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: _topRatedMedia.asMap().entries.map((entry) {
            final item = entry.value;
            final index = entry.key;
            final imageUrl = _getImageUrl(item);
            final color = _getMediaColor(item);
            final icon = _getMediaIcon(item);
            final categoryIndex = _getCategoryIndex(item, index);

            return GestureDetector(
              onTap: () => _navigateToDetail(item),
              child: Container(
                margin: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: color,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: color.withOpacity(0.2),
                              child: Icon(
                                icon,
                                color: color,
                                size: 50,
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: color.withOpacity(0.2),
                          child: Icon(
                            icon,
                            color: color,
                            size: 50,
                          ),
                        ),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rank Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${categoryIndex + 1} ${_getMediaType(item)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Title
                              Text(
                                _getItemTitle(item),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Rating
                              Text(
                                _getRatingInfo(item),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _topRatedMedia.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
                    .withOpacity(_currentIndex == entry.key ? 0.9 : 0.4),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}