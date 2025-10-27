class User {
  final String userId;
  final String username;
  final String email;
  final String avatarUrl;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }


  @override
  String toString() {
    return 'User(id: $userId, username: $username, email: $email)';
  }
}