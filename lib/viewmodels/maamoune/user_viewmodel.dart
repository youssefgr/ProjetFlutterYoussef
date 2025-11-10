import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:projetflutteryoussef/Models/maamoune/user.dart';
import 'package:projetflutteryoussef/repositories/maamoune/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  late SupabaseClient _supabase;

  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<User> get users => _users;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserViewModel() {
    _supabase = Supabase.instance.client;
  }

  /// Sync Google user to database - check if exists, if not create
  /// This handles BOTH new sign-ups AND existing users logging in again
  Future<User?> syncGoogleUser() async {
    _setLoading(true);
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        _error = 'No authenticated user';
        print('❌ Error: No authenticated user');
        return null;
      }

      print('🔍 Checking if user exists in database: ${authUser.id}');

      // Step 1: Check if user already exists in database
      var existingUser = await _repository.getUserById(authUser.id);
      if (existingUser != null) {
        print('✅ User already exists in database: ${existingUser.id}');
        _currentUser = existingUser;
        _error = null;
        notifyListeners();
        return existingUser;
      }

      print('👤 User not found, creating new user...');

      // Step 2: Create new user from Google auth
      final newUser = User(
        id: authUser.id,
        username: authUser.userMetadata?['full_name'] ??
            authUser.email?.split('@')[0] ??
            'User',
        email: authUser.email ?? '',
        avatarUrl: authUser.userMetadata?['avatar_url'] ?? '',
      );

      print('📝 Creating user: ${newUser.id}');
      await _repository.addUser(newUser);
      print('✅ User created successfully');

      _currentUser = newUser;
      _error = null;
      notifyListeners();
      return newUser;
    } catch (e) {
      _error = 'Failed to sync user: $e';
      print('❌ Error syncing user: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all users from database
  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      _users = await _repository.getAllUsers();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch users: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch current authenticated user's profile
  Future<void> fetchCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await _repository.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch current user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new user (usually handled by auth signup + trigger)
  Future<void> addUser(User user) async {
    _setLoading(true);
    try {
      await _repository.addUser(user);
      await fetchUsers(); // Refresh the list
      _error = null;
    } catch (e) {
      _error = 'Failed to add user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<void> updateUser(User updatedUser) async {
    _setLoading(true);
    try {
      await _repository.updateUser(updatedUser);
      // Update current user if it's the same user
      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
      }

      // Update in the users list
      final index = _users.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _users[index] = updatedUser;
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update specific fields of current user
  Future<void> updateCurrentUserFields(Map<String, dynamic> updates) async {
    if (_currentUser == null) {
      _error = 'No user is currently logged in';
      return;
    }

    _setLoading(true);
    try {
      await _repository.updateUserFields(_currentUser!.id, updates);
      await fetchCurrentUser(); // Refresh current user data
      _error = null;
    } catch (e) {
      _error = 'Failed to update user fields: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    _setLoading(true);
    try {
      await _repository.deleteUser(userId);
      // Remove from local list
      _users.removeWhere((u) => u.id == userId);
      // Clear current user if it was deleted
      if (_currentUser?.id == userId) {
        _currentUser = null;
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete user: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      return await _repository.getUserById(userId);
    } catch (e) {
      _error = 'Failed to get user: $e';
      return null;
    }
  }

  /// Search users by username
  Future<void> searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      await fetchUsers();
      return;
    }

    _setLoading(true);
    try {
      _users = await _repository.searchUsersByUsername(searchTerm);
      _error = null;
    } catch (e) {
      _error = 'Failed to search users: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _repository.signOut();
      _currentUser = null;
      _users = [];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Private helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
