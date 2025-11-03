enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'],
        userId: json['user_id'],
        friendId: json['friend_id'],
        status: FriendshipStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => FriendshipStatus.pending,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'friend_id': friendId,
        'status': status.name,
      };
}
