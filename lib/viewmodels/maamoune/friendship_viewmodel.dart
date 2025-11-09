import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';
import 'package:projetflutteryoussef/repositories/maamoune/friendship_repository.dart';

class FriendshipViewModel extends ChangeNotifier {
  final FriendshipRepository _repository = FriendshipRepository();
  List<Friendship> _friendships = [];

  List<Friendship> get friendships => _friendships;

  void fetchFriendships() {
    _friendships = _repository.getAllFriendships();
    notifyListeners();
  }

  void sendFriendRequest(Friendship friendship) {
    _repository.sendFriendRequest(friendship);
    fetchFriendships();
  }

  void updateFriendshipStatus(String id, FriendshipStatus status) {
    _repository.updateFriendshipStatus(id, status);
    fetchFriendships();
  }

  void deleteFriendship(String id) {
    _repository.removeFriendship(id);
    fetchFriendships();
  }

  List<Friendship> getPendingRequests(String userId) {
    return _repository.getPendingRequests(userId);
  }

  List<Friendship> getAcceptedFriends(String userId) {
    return _repository.getAcceptedFriends(userId);
  }

  List<Friendship> getSentRequests(String userId) {
    return _repository.getSentRequests(userId);
  }

  bool areFriends(String userId1, String userId2) {
    return _repository.areFriends(userId1, userId2);
  }

  Friendship? getFriendshipBetween(String userId1, String userId2) {
    return _repository.getFriendshipBetween(userId1, userId2);
  }
}