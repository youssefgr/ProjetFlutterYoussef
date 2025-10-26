import '../../Models/Akram/media_models.dart';
import '../../repositories/Akram/media_repository.dart';
import '../../utils/image_utils.dart';

class MediaViewModel {
  List<MediaItem> _mediaItems = [];
  List<MediaItem> get mediaItems => _mediaItems;

  // Search and filter properties
  String _searchQuery = '';
  MediaCategory? _selectedCategory;
  MediaViewStatus? _selectedStatus;
  final List<MediaGenre> _selectedGenres = [];

  // Getters for filter states
  String get searchQuery => _searchQuery;
  MediaCategory? get selectedCategory => _selectedCategory;
  MediaViewStatus? get selectedStatus => _selectedStatus;
  List<MediaGenre> get selectedGenres => List.from(_selectedGenres);

  // State management callbacks
  Function()? onMediaItemsUpdated;

  // Get filtered media items
  List<MediaItem> get filteredMediaItems {
    return _mediaItems.where((item) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category filter
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;

      // Status filter
      final matchesStatus = _selectedStatus == null || item.status == _selectedStatus;

      // Genre filter
      final matchesGenre = _selectedGenres.isEmpty ||
          item.genres.any((genre) => _selectedGenres.contains(genre));

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

  void toggleGenreFilter(MediaGenre genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    onMediaItemsUpdated?.call();
  }

  void clearAllFilters() {
    _selectedCategory = null;
    _selectedStatus = null;
    _selectedGenres.clear();
    _searchQuery = '';
    onMediaItemsUpdated?.call();
  }

  // Get current filter states
  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategory != null ||
        _selectedStatus != null ||
        _selectedGenres.isNotEmpty;
  }

  String get activeFiltersDescription {
    final filters = <String>[];
    if (_searchQuery.isNotEmpty) filters.add('Search: "$_searchQuery"');
    if (_selectedCategory != null) filters.add('Category: ${_selectedCategory.toString().split('.').last}');
    if (_selectedStatus != null) filters.add('Status: ${_selectedStatus.toString().split('.').last}');
    if (_selectedGenres.isNotEmpty) {
      filters.add('Genres: ${_selectedGenres.map((g) => g.toString().split('.').last).join(', ')}');
    }
    return filters.join(' • ');
  }

  Future<void> loadMediaItems() async {
    _mediaItems = await MediaRepository.loadMediaItems();
    onMediaItemsUpdated?.call();
  }

  Future<void> addMediaItem(MediaItem item) async {
    _mediaItems.add(item);
    await MediaRepository.saveMediaItems(_mediaItems);
    onMediaItemsUpdated?.call();
  }

  Future<void> updateMediaItem(MediaItem updatedItem) async {
    final index = _mediaItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _mediaItems[index] = updatedItem;
      await MediaRepository.saveMediaItems(_mediaItems);
      onMediaItemsUpdated?.call();
    }
  }

  Future<void> deleteMediaItem(String id) async {
    final item = _mediaItems.firstWhere((item) => item.id == id);
    if (item.imageUrl.isNotEmpty) {
      await ImageUtils.deleteImage(item.imageUrl);
    }
    _mediaItems.removeWhere((item) => item.id == id);
    await MediaRepository.saveMediaItems(_mediaItems);
    onMediaItemsUpdated?.call();
  }

  Future<void> updateMediaStatus(String itemId, MediaViewStatus newStatus) async {
    final index = _mediaItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _mediaItems[index] = _mediaItems[index].copyWith(status: newStatus);
      await MediaRepository.saveMediaItems(_mediaItems);
      onMediaItemsUpdated?.call();
    }
  }

  List<MediaItem> getItemsByStatus(MediaViewStatus status) {
    return filteredMediaItems.where((item) => item.status == status).toList();
  }
}