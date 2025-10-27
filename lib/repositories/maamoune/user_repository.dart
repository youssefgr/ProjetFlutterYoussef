import 'package:projetflutteryoussef/Models/maamoune/user.dart';
class UserRepository {
  final List<User> _users = [];

  // CREATE
  void addUser(User user) {
    _users.add(user);
  }

  // READ
  List<User> getAllUsers() {
    return List.unmodifiable(_users);
  }

  User? getUserById(String userId) {
    return _users.firstWhere((u) => u.userId == userId, orElse: () => User(userId: '', username: '', email: '', avatarUrl: ''));
  }

  // UPDATE
  void updateUser(User updatedUser) {
    final index = _users.indexWhere((u) => u.userId == updatedUser.userId);
    if (index != -1) {
      _users[index] = updatedUser;
    }
  }

  // DELETE
  void deleteUser(String userId) {
    _users.removeWhere((u) => u.userId == userId);
  }
}
