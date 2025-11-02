import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/community.dart';
import 'package:projetflutteryoussef/repositories/maamoune/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository = CommunityRepository();
  List<Community> _communities = [];

  List<Community> get communities => _communities;

  void fetchCommunities() {
    _communities = _repository.getAllCommunities();
    notifyListeners();
  }

  void createCommunity(Community community) {
    _repository.createCommunity(community);
    fetchCommunities();
  }

  void updateCommunity(Community community) {
    _repository.updateCommunity(community);
    fetchCommunities();
  }

  void deleteCommunity(String id) {
    _repository.deleteCommunity(id);
    fetchCommunities();
  }

  void joinCommunity(String communityId, String userId) {
    _repository.joinCommunity(communityId, userId);
    fetchCommunities();
  }

  void leaveCommunity(String communityId, String userId) {
    _repository.leaveCommunity(communityId, userId);
    fetchCommunities();
  }

  void promoteToAdmin(String communityId, String userId) {
    _repository.promoteToAdmin(communityId, userId);
    fetchCommunities();
  }

  void demoteFromAdmin(String communityId, String userId) {
    _repository.demoteFromAdmin(communityId, userId);
    fetchCommunities();
  }

  Community? getCommunityById(String id) {
    return _repository.getCommunityById(id);
  }

  List<Community> getCommunitiesByUserId(String userId) {
    return _repository.getCommunitiesByUserId(userId);
  }
}