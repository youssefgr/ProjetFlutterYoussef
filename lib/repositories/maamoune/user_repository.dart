import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:projetflutteryoussef/Models/maamoune/user.dart';

class UserRepository {
  // Get Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE - Add a new user profile to public.users
  /// Note: This is usually handled automatically by the database trigger
  /// when a user signs up via auth. Only use this if you need manual creation.
  Future<void> addUser(User user) async {
    try {
      await _supabase.from('users').insert(user.toJson());
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  /// READ - Get all users from the database
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((userData) => User.fromJson(userData))
          .toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  /// READ - Get a specific user by their ID
  Future<User?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return User.fromJson(response);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  /// READ - Get current authenticated user's profile
  Future<User?> getCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        return null;
      }

      return await getUserById(authUser.id);
    } catch (e) {
      print('Error fetching current user: $e');
      return null;
    }
  }

  /// UPDATE - Update user profile
  Future<void> updateUser(User updatedUser) async {
    try {
      await _supabase
          .from('users')
          .update(updatedUser.toJson())
          .eq('id', updatedUser.userId);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// UPDATE - Update specific fields of a user
  Future<void> updateUserFields(String userId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      print('Error updating user fields: $e');
      rethrow;
    }
  }

  /// UPDATE - Add a community to user's communities list
  Future<void> joinCommunity(String userId, String communityId) async {
    try {
      final user = await getUserById(userId);
      if (user != null && !user.communities.contains(communityId)) {
        final updatedCommunities = [...user.communities, communityId];
        await updateUserFields(userId, {'communities': updatedCommunities});
      }
    } catch (e) {
      print('Error joining community: $e');
      rethrow;
    }
  }

  /// UPDATE - Remove a community from user's communities list
  Future<void> leaveCommunity(String userId, String communityId) async {
    try {
      final user = await getUserById(userId);
      if (user != null && user.communities.contains(communityId)) {
        final updatedCommunities = user.communities
            .where((id) => id != communityId)
            .toList();
        await updateUserFields(userId, {'communities': updatedCommunities});
      }
    } catch (e) {
      print('Error leaving community: $e');
      rethrow;
    }
  }

  /// DELETE - Delete a user profile
  /// Note: This only deletes from public.users.
  /// To delete from auth.users, use: _supabase.auth.admin.deleteUser(userId)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// SEARCH - Search users by username
  Future<List<User>> searchUsersByUsername(String searchTerm) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .ilike('username', '%$searchTerm%')
          .order('username', ascending: true);

      return (response as List)
          .map((userData) => User.fromJson(userData))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// STREAM - Listen to real-time changes for a specific user
  Stream<User?> streamUser(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
      if (data.isEmpty) return null;
      return User.fromJson(data.first);
    });
  }

  /// STREAM - Listen to real-time changes for all users
  Stream<List<User>> streamAllUsers() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) {
      return data.map((userData) => User.fromJson(userData)).toList();
    });
  }

  /// AUTH - Sign up a new user with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username ?? email.split('@')[0],
          'avatar_url': avatarUrl ?? '',
        },
      );

      if (response.user != null) {
        // Wait a bit for the trigger to create the profile
        await Future.delayed(const Duration(milliseconds: 500));
        return await getUserById(response.user!.id);
      }
      return null;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  /// AUTH - Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await getUserById(response.user!.id);
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  /// AUTH - Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
