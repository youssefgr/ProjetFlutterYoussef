import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Models/Akram/movie_model.dart';
import '../../Models/Akram/series_model.dart';
import '../../Models/Akram/anime_model.dart';
import '../../Models/Akram/media_models.dart';
import '../../repositories/Akram/media_repository.dart';

class MediaViewModel {
  // Local media items (from Supabase)
  List<MediaItem> _mediaItems = [];
  List<MediaItem> get mediaItems => _mediaItems;

  // API media items
  List<Movie> _movies = [];
  List<Series> _series = [];
  List<Anime> _anime = [];

  List<Movie> get movies => _movies;
  List<Series> get series => _series;
  List<Anime> get anime => _anime;

  // Search and filter properties
  String _searchQuery = '';
  MediaCategory? _selectedCategory;
  MediaViewStatus? _selectedStatus;
  MediaGenre? _selectedGenre;

  String get searchQuery => _searchQuery;
  MediaCategory? get selectedCategory => _selectedCategory;
  MediaViewStatus? get selectedStatus => _selectedStatus;
  MediaGenre? get selectedGenre => _selectedGenre;

  // Loading states
  bool _isLoadingMovies = false;
  bool _isLoadingSeries = false;
  bool _isLoadingAnime = false;

  bool get isLoadingMovies => _isLoadingMovies;
  bool get isLoadingSeries => _isLoadingSeries;
  bool get isLoadingAnime => _isLoadingAnime;
  bool get isLoadingAny => _isLoadingMovies || _isLoadingSeries || _isLoadingAnime;

  // Error states
  String? _moviesError;
  String? _seriesError;
  String? _animeError;

  String? get moviesError => _moviesError;
  String? get seriesError => _seriesError;
  String? get animeError => _animeError;

  // State management callbacks
  Function()? onMediaItemsUpdated;

  // API Keys
  static const String _tmdbApiKey = 'e30a8bbae804539701776e9413710ee0';
  static const String _malClientId = 'fa38936ac71c9615ff9e37646443b609';

  // Get filtered media items
  List<MediaItem> get filteredMediaItems {
    return _mediaItems.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null || item.status == _selectedStatus;
      final matchesGenre = _selectedGenre == null || item.genre == _selectedGenre;

      return matchesSearch && matchesCategory && matchesStatus && matchesGenre;
    }).toList();
  }

  // Search methods
  void setSearchQuery(String query) {
    _searchQuery = query;
    onMediaItemsUpdated?.call();
  }

  void clearSearch() {
    _searchQuery = '';
    onMediaItemsUpdated?.call();
  }

  // Filter methods
  void setCategoryFilter(MediaCategory? category) {
    _selectedCategory = category;
    onMediaItemsUpdated?.call();
  }

  void setStatusFilter(MediaViewStatus? status) {
    _selectedStatus = status;
    onMediaItemsUpdated?.call();
  }

  void setGenreFilter(MediaGenre? genre) {
    _selectedGenre = genre;
    onMediaItemsUpdated?.call();
  }

  void clearAllFilters() {
    _selectedCategory = null;
    _selectedStatus = null;
    _selectedGenre = null;
    _searchQuery = '';
    onMediaItemsUpdated?.call();
  }

  // Get current filter states
  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedStatus != null ||
        _selectedGenre != null;
  }

  String get activeFiltersDescription {
    final filters = <String>[];
    if (_searchQuery.isNotEmpty) filters.add('Search: "$_searchQuery"');
    if (_selectedCategory != null) filters.add('Category: ${_selectedCategory.toString().split('.').last}');
    if (_selectedStatus != null) filters.add('Status: ${_selectedStatus.toString().split('.').last}');
    if (_selectedGenre != null) filters.add('Genre: ${_selectedGenre.toString().split('.').last}');
    return filters.join(' • ');
  }

  // Load all media (both local and API)
  Future<void> loadAllMedia() async {
    await Future.wait([
      loadMediaItems(),
      loadMovies(),
      loadSeries(),
      loadAnime(),
    ]);
  }

  // Load local media items from Supabase
  Future<void> loadMediaItems() async {
    try {
      _mediaItems = await MediaRepository.loadMediaItems();
      onMediaItemsUpdated?.call();
    } catch (e) {
      print('Error loading media items: $e');
    }
  }

  // Add media item to Supabase
  Future<void> addMediaItem(MediaItem item) async {
    try {
      await MediaRepository.addMediaItem(item);
      await loadMediaItems();
    } catch (e) {
      print('Error adding media item: $e');
      rethrow;
    }
  }

  // Update media item in Supabase
  Future<void> updateMediaItem(MediaItem updatedItem) async {
    try {
      await MediaRepository.updateMediaItem(updatedItem);
      await loadMediaItems();
    } catch (e) {
      print('Error updating media item: $e');
      rethrow;
    }
  }

  // Delete media item from Supabase
  Future<void> deleteMediaItem(String id) async {
    try {
      await MediaRepository.deleteMediaItem(id);
      await loadMediaItems();
    } catch (e) {
      print('Error deleting media item: $e');
      rethrow;
    }
  }

  // Update media status in Supabase
  Future<void> updateMediaStatus(String itemId, MediaViewStatus newStatus) async {
    try {
      final index = _mediaItems.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final updatedItem = _mediaItems[index].copyWith(status: newStatus);
        await MediaRepository.updateMediaItem(updatedItem);
        await loadMediaItems();
      }
    } catch (e) {
      print('Error updating media status: $e');
      rethrow;
    }
  }

  List<MediaItem> getItemsByStatus(MediaViewStatus status) {
    return filteredMediaItems.where((item) => item.status == status).toList();
  }

  // ========== API METHODS ==========

  // Load Movies from TMDB
  Future<void> loadMovies() async {
    _isLoadingMovies = true;
    _moviesError = null;
    onMediaItemsUpdated?.call();

    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/popular?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final movies = <Movie>[];
        for (var result in results.take(20)) {
          final movieId = result['id'];
          final detailResponse = await http.get(
            Uri.parse('https://api.themoviedb.org/3/movie/$movieId?api_key=$_tmdbApiKey'),
          );

          if (detailResponse.statusCode == 200) {
            final detailData = json.decode(detailResponse.body);
            movies.add(Movie.fromJson(detailData));
          }
        }

        _movies = movies;
        _moviesError = null;
      } else {
        _moviesError = 'Failed to load movies: ${response.statusCode}';
      }
    } catch (e) {
      _moviesError = 'Error loading movies: $e';
      print(_moviesError);
    } finally {
      _isLoadingMovies = false;
      onMediaItemsUpdated?.call();
    }
  }

  // Load Series from TMDB
  Future<void> loadSeries() async {
    _isLoadingSeries = true;
    _seriesError = null;
    onMediaItemsUpdated?.call();

    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/popular?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        final series = <Series>[];
        for (var result in results.take(20)) {
          final seriesId = result['id'];
          final detailResponse = await http.get(
            Uri.parse('https://api.themoviedb.org/3/tv/$seriesId?api_key=$_tmdbApiKey'),
          );

          if (detailResponse.statusCode == 200) {
            final detailData = json.decode(detailResponse.body);
            series.add(Series.fromJson(detailData));
          }
        }

        _series = series;
        _seriesError = null;
      } else {
        _seriesError = 'Failed to load series: ${response.statusCode}';
      }
    } catch (e) {
      _seriesError = 'Error loading series: $e';
      print(_seriesError);
    } finally {
      _isLoadingSeries = false;
      onMediaItemsUpdated?.call();
    }
  }

  // Load Anime from MyAnimeList
  Future<void> loadAnime() async {
    _isLoadingAnime = true;
    _animeError = null;
    onMediaItemsUpdated?.call();

    try {
      final response = await http.get(
        Uri.parse('https://api.myanimelist.net/v2/anime/ranking?ranking_type=bypopularity&limit=20&fields=synopsis,mean,start_date,genres,studios'),
        headers: {
          'X-MAL-CLIENT-ID': _malClientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'];

        _anime = results.map((json) => Anime.fromJson(json)).toList();
        _animeError = null;
      } else {
        _animeError = 'Failed to load anime: ${response.statusCode}';
      }
    } catch (e) {
      _animeError = 'Error loading anime: $e';
      print(_animeError);
    } finally {
      _isLoadingAnime = false;
      onMediaItemsUpdated?.call();
    }
  }

  // Refresh API media
  Future<void> refreshApiMedia() async {
    await Future.wait([
      loadMovies(),
      loadSeries(),
      loadAnime(),
    ]);
  }
}