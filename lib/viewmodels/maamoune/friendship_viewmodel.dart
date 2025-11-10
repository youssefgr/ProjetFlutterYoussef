import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';
import 'package:projetflutteryoussef/repositories/maamoune/friendship_repository.dart';

class FriendshipViewModel extends ChangeNotifier {
  final FriendshipRepository _repository = FriendshipRepository();

  List<Friendship> _friendships = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Friendship> get friendships => _friendships;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all friendships from database
  Future<void> fetchFriendships() async {
    _setLoading(true);
    try {
      _friendships = await _repository.getAllFriendships();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch friendships: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch friendships for a specific user
  Future<List<Friendship>> fetchUserFriendships(String userId) async {
    _setLoading(true);
    try {
      return await _repository.getFriendshipsByUserId(userId);
    } catch (e) {
      _error = 'Failed to fetch user friendships: $e';
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Get pending friend requests for a user (received requests)
  List<Friendship> getPendingRequests(String userId) {
    return _friendships
        .where((f) => f.friendId == userId && f.status == FriendshipStatus.pending)
        .toList();
  }

  /// Get accepted friends of a user
  List<Friendship> getAcceptedFriends(String userId) {
    return _friendships
        .where((f) =>
    (f.userId == userId || f.friendId == userId) &&
        f.status == FriendshipStatus.accepted)
        .toList();
  }

  /// Get sent friend requests (pending requests sent by user)
  List<Friendship> getSentRequests(String userId) {
    return _friendships
        .where((f) => f.userId == userId && f.status == FriendshipStatus.pending)
        .toList();
  }

  /// Get blocked users
  List<Friendship> getBlockedUsers(String userId) {
    return _friendships
        .where((f) => f.userId == userId && f.status == FriendshipStatus.blocked)
        .toList();
  }

  /// Send a friend request
  Future<void> sendFriendRequest(Friendship friendship) async {
    _setLoading(true);
    try {
      await _repository.sendFriendRequest(friendship);
      await fetchFriendships();
      _error = null;
    } catch (e) {
      _error = 'Failed to send friend request: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    _setLoading(true);
    try {
      await _repository.acceptFriendRequest(friendshipId);
      final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
      if (index != -1) {
        _friendships[index] = Friendship(
          friendshipId: _friendships[index].friendshipId,
          userId: _friendships[index].userId,
          friendId: _friendships[index].friendId,
          status: FriendshipStatus.accepted,
        );
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to accept friend request: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update friendship status
  Future<void> updateFriendshipStatus(String friendshipId, FriendshipStatus status) async {
    _setLoading(true);
    try {
      await _repository.updateFriendshipStatus(friendshipId, status);
      final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
      if (index != -1) {
        _friendships[index] = Friendship(
          friendshipId: _friendships[index].friendshipId,
          userId: _friendships[index].userId,
          friendId: _friendships[index].friendId,
          status: status,
        );
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update friendship status: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Block a user
  Future<void> blockUser(String friendshipId) async {
    _setLoading(true);
    try {
      await _repository.blockUser(friendshipId);
      await fetchFriendships();
      _error = null;
    } catch (e) {
      _error = 'Failed to block user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String friendshipId) async {
    _setLoading(true);
    try {
      await _repository.unblockUser(friendshipId);
      await fetchFriendships();
      _error = null;
    } catch (e) {
      _error = 'Failed to unblock user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a friendship (unfriend or cancel request)
  Future<void> deleteFriendship(String friendshipId) async {
    _setLoading(true);
    try {
      await _repository.deleteFriendship(friendshipId);
      _friendships.removeWhere((f) => f.friendshipId == friendshipId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete friendship: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String friendshipId) async {
    _setLoading(true);
    try {
      await _repository.declineFriendRequest(friendshipId);
      _friendships.removeWhere((f) => f.friendshipId == friendshipId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to decline friend request: $e';
    } finally {
      _setLoading(false);
    }
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
