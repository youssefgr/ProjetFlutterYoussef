import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Create User from Supabase database row (public.users table)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      communities: json['communities'] != null
          ? List<String>.from(json['communities'])
          : [],
    );
  }

  /// Create User from Supabase Auth User object
  /// This is useful when you just authenticated and want to create a User object
  factory User.fromAuthUser(AuthUser authUser) {
    return User(
      userId: authUser.id,
      username: authUser.userMetadata?['username'] ??
          authUser.email?.split('@')[0] ?? '',
      email: authUser.email ?? '',
      avatarUrl: authUser.userMetadata?['avatar_url'] ?? '',
      communities: [],
    );
  }

  /// Convert User to JSON for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'communities': communities,
    };
  }

  /// Create a copy of User with updated fields
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
