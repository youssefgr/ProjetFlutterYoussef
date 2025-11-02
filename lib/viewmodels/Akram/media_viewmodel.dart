import 'package:http/http.dart' as http;
import 'dart:convert';
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
  List<Manga> _manga = []; // Added manga list

  List<Movie> get movies => _movies;
  List<Series> get series => _series;
  List<Anime> get anime => _anime;
  List<Manga> get manga => _manga; // Added manga getter

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
  bool _isLoadingManga = false; // Added manga loading state

  bool get isLoadingMovies => _isLoadingMovies;
  bool get isLoadingSeries => _isLoadingSeries;
  bool get isLoadingAnime => _isLoadingAnime;
  bool get isLoadingManga => _isLoadingManga; // Added manga loading getter
  bool get isLoadingAny => _isLoadingMovies || _isLoadingSeries || _isLoadingAnime || _isLoadingManga; // Updated

  // Error states
  String? _moviesError;
  String? _seriesError;
  String? _animeError;
  String? _mangaError; // Added manga error state

  String? get moviesError => _moviesError;
  String? get seriesError => _seriesError;
  String? get animeError => _animeError;
  String? get mangaError => _mangaError; // Added manga error getter

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
      loadManga(), // Added manga loading
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

  // Load Movies from TMDB with parallel detail loading
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

        // Get movie IDs first
        final movieIds = results.take(20).map((result) => result['id'] as int).toList();

        // Load all movie details in parallel
        final movieFutures = movieIds.map((movieId) => _fetchMovieDetail(movieId));
        final movies = await Future.wait(movieFutures);

        _movies = movies.whereType<Movie>().toList();
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

  // Helper method to fetch individual movie details
  Future<Movie?> _fetchMovieDetail(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/$movieId?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final detailData = json.decode(response.body);
        return Movie.fromJson(detailData);
      }
    } catch (e) {
      print('Error fetching movie detail $movieId: $e');
    }
    return null;
  }

  // Load Series from TMDB with parallel detail loading
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

        // Get series IDs first
        final seriesIds = results.take(20).map((result) => result['id'] as int).toList();

        // Load all series details in parallel
        final seriesFutures = seriesIds.map((seriesId) => _fetchSeriesDetail(seriesId));
        final series = await Future.wait(seriesFutures);

        _series = series.whereType<Series>().toList();
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

  // Helper method to fetch individual series details
  Future<Series?> _fetchSeriesDetail(int seriesId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/$seriesId?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final detailData = json.decode(response.body);
        return Series.fromJson(detailData);
      }
    } catch (e) {
      print('Error fetching series detail $seriesId: $e');
    }
    return null;
  }

  // Load Anime from MyAnimeList (already efficient)
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

  // Load Manga from MyAnimeList
  Future<void> loadManga() async {
    _isLoadingManga = true;
    _mangaError = null;
    onMediaItemsUpdated?.call();

    try {
      final response = await http.get(
        Uri.parse('https://api.myanimelist.net/v2/manga/ranking?ranking_type=bypopularity&limit=20&fields=synopsis,mean,start_date,genres,authors'),
        headers: {
          'X-MAL-CLIENT-ID': _malClientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'];

        _manga = results.map((json) => Manga.fromJson(json)).toList();
        _mangaError = null;
      } else {
        _mangaError = 'Failed to load manga: ${response.statusCode}';
      }
    } catch (e) {
      _mangaError = 'Error loading manga: $e';
      print(_mangaError);
    } finally {
      _isLoadingManga = false;
      onMediaItemsUpdated?.call();
    }
  }

  // Refresh API media with parallel loading
  Future<void> refreshApiMedia() async {
    await Future.wait([
      loadMovies(),
      loadSeries(),
      loadAnime(),
      loadManga(), // Added manga refresh
    ]);
  }

  // Optimized method to load only basic info first, then details on demand
  Future<void> loadMediaBasicFirst() async {
    // Load basic lists first (without detailed info)
    await Future.wait([
      _loadMoviesBasic(),
      _loadSeriesBasic(),
      loadAnime(), // Anime is already efficient
      loadManga(), // Manga is already efficient
    ]);
  }

  // Load movies with basic info only
  Future<void> _loadMoviesBasic() async {
    _isLoadingMovies = true;
    onMediaItemsUpdated?.call();

    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/movie/popular?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        _movies = results.take(20).map((result) => Movie.fromJson(result)).toList();
        _moviesError = null;
      }
    } catch (e) {
      _moviesError = 'Error loading movies: $e';
    } finally {
      _isLoadingMovies = false;
      onMediaItemsUpdated?.call();
    }
  }

  // Load series with basic info only
  Future<void> _loadSeriesBasic() async {
    _isLoadingSeries = true;
    onMediaItemsUpdated?.call();

    try {
      final response = await http.get(
        Uri.parse('https://api.themoviedb.org/3/tv/popular?api_key=$_tmdbApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        _series = results.take(20).map((result) => Series.fromJson(result)).toList();
        _seriesError = null;
      }
    } catch (e) {
      _seriesError = 'Error loading series: $e';
    } finally {
      _isLoadingSeries = false;
      onMediaItemsUpdated?.call();
    }
  }

  // Load detailed info for a specific movie when needed
  Future<void> loadMovieDetail(int movieId) async {
    try {
      final movie = await _fetchMovieDetail(movieId);
      if (movie != null) {
        final index = _movies.indexWhere((m) => m.id == movieId);
        if (index != -1) {
          _movies[index] = movie;
          onMediaItemsUpdated?.call();
        }
      }
    } catch (e) {
      print('Error loading movie detail: $e');
    }
  }

  // Load detailed info for a specific series when needed
  Future<void> loadSeriesDetail(int seriesId) async {
    try {
      final series = await _fetchSeriesDetail(seriesId);
      if (series != null) {
        final index = _series.indexWhere((s) => s.id == seriesId);
        if (index != -1) {
          _series[index] = series;
          onMediaItemsUpdated?.call();
        }
      }
    } catch (e) {
      print('Error loading series detail: $e');
    }
  }
}