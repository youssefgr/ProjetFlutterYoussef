class User {
  final String userId;
  final String username;
  final String email;
  final String avatarUrl;
  final List<String> communities; // List of community IDs user has joined

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.avatarUrl,
    this.communities = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      communities: json['communities'] != null
          ? List<String>.from(json['communities'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'communities': communities,
    };
  }

  User copyWith({
    String? userId,
    String? username,
    String? email,
    String? avatarUrl,
    List<String>? communities,
  }) {
    return User(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      communities: communities ?? this.communities,
    );
  }

  @override
  String toString() {
    return 'User(id: $userId, username: $username, email: $email)';
  }
}