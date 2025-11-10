import 'package:supabase_flutter/supabase_flutter.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
  });

  /// Create User from Supabase public.users table
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
    );
  }

  /// Create User from Supabase Auth User object
  factory User.fromAuthUser(AuthUser authUser) {
    return User(
      id: authUser.id,
      username: authUser.userMetadata?['username'] ??
          authUser.email?.split('@')[0] ??
          '',
      email: authUser.email ?? '',
      avatarUrl: authUser.userMetadata?['avatar_url'] ?? '',
    );
  }

  /// Convert User to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email)';
  }
}
