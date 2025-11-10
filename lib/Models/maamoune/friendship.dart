enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final String friendshipId;
  final String userId;
  final String friendId;
  final FriendshipStatus status;

  Friendship({
    required this.friendshipId,
    required this.userId,
    required this.friendId,
    required this.status,
  });

  /// Create Friendship from Supabase public.friendships table
  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      friendshipId: map['friendship_id'] ?? '',
      userId: map['user_id'] ?? '',
      friendId: map['friend_id'] ?? '',
      status: _statusFromString(map['status']),
    );
  }

  /// Convert Friendship to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'friendship_id': friendshipId,
      'user_id': userId,
      'friend_id': friendId,
      'status': status.name,
    };
  }

  static FriendshipStatus _statusFromString(String? value) {
    switch (value) {
      case 'accepted':
        return FriendshipStatus.accepted;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }

  @override
  String toString() {
    return 'Friendship(id: $friendshipId, user: $userId, friend: $friendId, status: $status)';
  }
}
