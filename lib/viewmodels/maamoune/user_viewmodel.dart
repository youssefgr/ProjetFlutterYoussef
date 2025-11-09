import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/user.dart';
import 'package:projetflutteryoussef/repositories/maamoune/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  List<User> _users = [];

  List<User> get users => _users;

  void fetchUsers() {
    _users = _repository.getAllUsers();
    notifyListeners();
  }

  void addUser(User user) {
    _repository.addUser(user);
    fetchUsers();
  }

  void updateUser(User updatedUser) {
    _repository.updateUser(updatedUser);
    fetchUsers();
  }

  void deleteUser(String id) {
    _repository.deleteUser(id);
    fetchUsers();
  }

  User? getUserById(String id) {
    return _repository.getUserById(id);
  }
}
