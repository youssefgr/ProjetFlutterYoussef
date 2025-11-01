import '../../Models/Akram/media_models.dart';
import '../../repositories/Akram/media_repository.dart';

class MediaViewModel {
  List<MediaItem> _mediaItems = [];
  List<MediaItem> get mediaItems => _mediaItems;

  // Search and filter properties
  String _searchQuery = '';
  MediaCategory? _selectedCategory;
  MediaViewStatus? _selectedStatus;
  MediaGenre? _selectedGenre; // Changed from List to single value

  // Getters for filter states
  String get searchQuery => _searchQuery;
  MediaCategory? get selectedCategory => _selectedCategory;
  MediaViewStatus? get selectedStatus => _selectedStatus;
  MediaGenre? get selectedGenre => _selectedGenre; // Changed

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

      // Genre filter (single value now)
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

  // Load media items from Supabase
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
}