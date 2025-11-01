import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../Models/Akram/movie_model.dart';
import '../../../Models/Akram/series_model.dart';
import '../../../Models/Akram/anime_model.dart';

class MediaHome extends StatefulWidget {
  const MediaHome({super.key});

  @override
  State<MediaHome> createState() => _MediaHomeState();
}

class _MediaHomeState extends State<MediaHome> {
  bool _isLoading = true;
  List<Movie> _movies = [];
  List<Series> _series = [];
  List<Anime> _anime = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadMovies(),
      _loadSeries(),
      _loadAnime(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMovies() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/popular?api_key=e30a8bbae804539701776e9413710ee0'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        setState(() {
          _movies = results.map((json) => Movie.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading movies: $e');
    }
  }

  Future<void> _loadSeries() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/popular?api_key=e30a8bbae804539701776e9413710ee0'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        setState(() {
          _series = results.map((json) => Series.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading series: $e');
    }
  }

  Future<void> _loadAnime() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.myanimelist.net/v2/anime/ranking?ranking_type=bypopularity&limit=20'),
        headers: {
          'X-MAL-CLIENT-ID': 'fa38936ac71c9615ff9e37646443b609',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'];

        setState(() {
          _anime = results.map((json) => Anime.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading anime: $e');
    }
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHorizontalSection(_movies, 'Movies', Colors.orange),
              const SizedBox(height: 16),
              _buildHorizontalSection(_series, 'Series', Colors.blue),
              const SizedBox(height: 16),
              _buildHorizontalSection(_anime, 'Anime', Colors.purple),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection(List<dynamic> items, String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$title | ${items.length}',
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
          child: items.isEmpty
              ? _buildEmptySection(title, color)
              : _buildHorizontalScrollView(items, color),
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
      onTap: () {
        // Handle tap if needed
      },
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}