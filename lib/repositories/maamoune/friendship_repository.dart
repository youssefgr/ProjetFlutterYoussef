import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';

class FriendshipRepository {
  final List<Friendship> _friendships = [];

  // CREATE (send friend request)
  void sendFriendRequest(Friendship friendship) {
    // Check if friendship already exists
    final exists = _friendships.any((f) =>
    (f.userId == friendship.userId && f.friendId == friendship.friendId) ||
        (f.userId == friendship.friendId && f.friendId == friendship.userId)
    );

    if (!exists) {
      _friendships.add(friendship);
    }
  }

  // READ
  List<Friendship> getAllFriendships() {
    return List.unmodifiable(_friendships);
  }

  // Get pending friend requests for a user
  List<Friendship> getPendingRequests(String userId) {
    return _friendships
        .where((f) => f.friendId == userId && f.status == FriendshipStatus.pending)
        .toList();
  }

  // Get accepted friends of a user
  List<Friendship> getAcceptedFriends(String userId) {
    return _friendships
        .where((f) =>
    (f.userId == userId || f.friendId == userId) &&
        f.status == FriendshipStatus.accepted)
        .toList();
  }

  // Get sent friend requests
  List<Friendship> getSentRequests(String userId) {
    return _friendships
        .where((f) => f.userId == userId && f.status == FriendshipStatus.pending)
        .toList();
  }

  // UPDATE (accept, block, etc.)
  void updateFriendshipStatus(String friendshipId, FriendshipStatus newStatus) {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index != -1) {
      final friendship = _friendships[index];
      _friendships[index] = Friendship(
        friendshipId: friendship.friendshipId,
        userId: friendship.userId,
        friendId: friendship.friendId,
        status: newStatus,
      );
    }
  }

  // DELETE (remove friend or reject request)
  void removeFriendship(String friendshipId) {
    _friendships.removeWhere((f) => f.friendshipId == friendshipId);
  }

  // Check if users are friends
  bool areFriends(String userId1, String userId2) {
    return _friendships.any((f) =>
    ((f.userId == userId1 && f.friendId == userId2) ||
        (f.userId == userId2 && f.friendId == userId1)) &&
        f.status == FriendshipStatus.accepted
    );
  }

  // Check if friend request exists
  Friendship? getFriendshipBetween(String userId1, String userId2) {
    try {
      return _friendships.firstWhere((f) =>
      (f.userId == userId1 && f.friendId == userId2) ||
          (f.userId == userId2 && f.friendId == userId1)
      );
    } catch (e) {
      return null;
    }
  }
}