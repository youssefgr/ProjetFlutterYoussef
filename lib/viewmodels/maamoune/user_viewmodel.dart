import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/user.dart';
import 'package:projetflutteryoussef/repositories/maamoune/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();

  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<User> get users => _users;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
      if (_currentUser?.userId == updatedUser.userId) {
        _currentUser = updatedUser;
      }
      // Update in the users list
      final index = _users.indexWhere((u) => u.userId == updatedUser.userId);
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
      await _repository.updateUserFields(_currentUser!.userId, updates);
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
      _users.removeWhere((u) => u.userId == userId);
      // Clear current user if it was deleted
      if (_currentUser?.userId == userId) {
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

  /// Join a community
  Future<void> joinCommunity(String communityId) async {
    if (_currentUser == null) {
      _error = 'No user is currently logged in';
      return;
    }
    _setLoading(true);
    try {
      await _repository.joinCommunity(_currentUser!.userId, communityId);
      await fetchCurrentUser(); // Refresh to get updated communities
      _error = null;
    } catch (e) {
      _error = 'Failed to join community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Leave a community
  Future<void> leaveCommunity(String communityId) async {
    if (_currentUser == null) {
      _error = 'No user is currently logged in';
      return;
    }
    _setLoading(true);
    try {
      await _repository.leaveCommunity(_currentUser!.userId, communityId);
      await fetchCurrentUser(); // Refresh to get updated communities
      _error = null;
    } catch (e) {
      _error = 'Failed to leave community: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? username,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        avatarUrl: avatarUrl,
      );
      _error = null;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = 'Failed to sign up: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      _error = null;
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      _error = 'Failed to sign in: $e';
      return false;
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
