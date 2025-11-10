import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:projetflutteryoussef/Models/maamoune/user.dart';

class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE - Add a new user profile to public.users
  Future<void> addUser(User user) async {
    try {
      print('📝 Adding user to database: ${user.id}');
      await _supabase.from('users').insert(user.toMap());
      print('✅ User added successfully');
    } catch (e) {
      print('❌ Error adding user: $e');
      throw Exception('Error adding user: $e');
    }
  }

  /// READ - Get all users from the database
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select();
      return (response as List)
          .map((userData) => User.fromMap(userData))
          .toList();
    } catch (e) {
      throw Exception('Error fetching all users: $e');
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
        print('⚠️ User not found: $userId');
        return null;
      }

      return User.fromMap(response);
    } catch (e) {
      throw Exception('Error fetching user by ID: $e');
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
      throw Exception('Error fetching current user: $e');
    }
  }

  /// UPDATE - Update user profile
  Future<void> updateUser(User updatedUser) async {
    try {
      print('📝 Updating user: ${updatedUser.id}');
      await _supabase
          .from('users')
          .update(updatedUser.toMap())
          .eq('id', updatedUser.id);
      print('✅ User updated successfully');
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// UPDATE - Update specific fields of a user
  Future<void> updateUserFields(String userId, Map<String, dynamic> updates) async {
    try {
      print('📝 Updating user fields: $userId');
      await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId);
      print('✅ User fields updated successfully');
    } catch (e) {
      throw Exception('Error updating user fields: $e');
    }
  }

  /// DELETE - Delete a user profile
  Future<void> deleteUser(String userId) async {
    try {
      print('🗑️ Deleting user: $userId');
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);
      print('✅ User deleted successfully');
    } catch (e) {
      throw Exception('Error deleting user: $e');
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
          .map((userData) => User.fromMap(userData))
          .toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  /// AUTH - Sign up a new user with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      print('📝 Signing up user: $email');
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username ?? email.split('@')[0],
          'avatar_url': avatarUrl ?? '',
        },
      );

      if (response.user != null) {
        await Future.delayed(const Duration(milliseconds: 500));
        return await getUserById(response.user!.id);
      }

      return null;
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  }

  /// AUTH - Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('📝 Signing in user: $email');
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await getUserById(response.user!.id);
      }

      return null;
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  }

  /// AUTH - Sign out
  Future<void> signOut() async {
    try {
      print('👋 Signing out user');
      await _supabase.auth.signOut();
      print('✅ Signed out successfully');
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }
}
