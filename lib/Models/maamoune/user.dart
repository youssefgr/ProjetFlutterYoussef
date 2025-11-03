class AppUser {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        avatarUrl: json['avatar_url'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
      };
}
