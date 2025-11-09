import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/community.dart';
import 'package:projetflutteryoussef/repositories/maamoune/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository = CommunityRepository();

  List<Community> _communities = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Community> get communities => _communities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all communities from database
  Future<void> fetchCommunities() async {
    _setLoading(true);
    try {
      _communities = await _repository.getAllCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch communities: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new community
  Future<void> createCommunity(Community community) async {
    _setLoading(true);
    try {
      await _repository.createCommunity(community);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to create community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update a community
  Future<void> updateCommunity(Community community) async {
    _setLoading(true);
    try {
      await _repository.updateCommunity(community);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to update community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a community
  Future<void> deleteCommunity(String id) async {
    _setLoading(true);
    try {
      await _repository.deleteCommunity(id);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to delete community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Join a community
  Future<void> joinCommunity(String communityId, String userId) async {
    _setLoading(true);
    try {
      await _repository.joinCommunity(communityId, userId);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to join community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Leave a community
  Future<void> leaveCommunity(String communityId, String userId) async {
    _setLoading(true);
    try {
      await _repository.leaveCommunity(communityId, userId);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to leave community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Promote a user to admin
  Future<void> promoteToAdmin(String communityId, String userId) async {
    _setLoading(true);
    try {
      await _repository.promoteToAdmin(communityId, userId);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to promote to admin: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Demote a user from admin
  Future<void> demoteFromAdmin(String communityId, String userId) async {
    _setLoading(true);
    try {
      await _repository.demoteFromAdmin(communityId, userId);
      await fetchCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to demote from admin: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Get a community by ID
  Community? getCommunityById(String id) {
    try {
      return _communities.firstWhere((c) => c.communityId == id);
    } catch (e) {
      return null;
    }
  }

  /// Get communities by user ID
  List<Community> getCommunitiesByUserId(String userId) {
    return _communities.where((c) => c.isMember(userId)).toList();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Private helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
