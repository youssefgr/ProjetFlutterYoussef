import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';

class FriendshipRepository {
  final List<Friendship> _friendships = [];

  // CREATE (send friend request)
  void sendFriendRequest(Friendship friendship) {
    _friendships.add(friendship);
  }

  // READ
  List<Friendship> getAllFriendships() {
    return List.unmodifiable(_friendships);
  }

  // Get friends of a specific user
  List<Friendship> getFriendsOfUser(String userId) {
    return _friendships
        .where((f) =>
    (f.userId == userId || f.friendId == userId) &&
        f.status == FriendshipStatus.accepted)
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

  // DELETE (remove friend)
  void removeFriendship(String friendshipId) {
    _friendships.removeWhere((f) => f.friendshipId == friendshipId);
  }
}
