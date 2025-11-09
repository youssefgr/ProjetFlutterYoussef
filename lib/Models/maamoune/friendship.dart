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

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      friendshipId: json['friendship_id'] ?? '',
      userId: json['user_id'] ?? '',
      friendId: json['friend_id'] ?? '',
      status: _statusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
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
