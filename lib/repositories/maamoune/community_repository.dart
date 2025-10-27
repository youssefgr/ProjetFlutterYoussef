import 'package:projetflutteryoussef/Models/maamoune/community.dart';

class CommunityRepository {
  final List<Community> _communities = [];

  // CREATE
  void createCommunity(Community community) {
    _communities.add(community);
  }

  // READ
  List<Community> getAllCommunities() {
    return List.unmodifiable(_communities);
  }

  Community? getCommunityById(String id) {
    return _communities.firstWhere(
          (c) => c.communityId == id,
      orElse: () => Community(communityId: '', name: '', description: '', ownerId: ''),
    );
  }

  // UPDATE
  void updateCommunity(Community updatedCommunity) {
    final index = _communities.indexWhere((c) => c.communityId == updatedCommunity.communityId);
    if (index != -1) {
      _communities[index] = updatedCommunity;
    }
  }

  // DELETE
  void deleteCommunity(String id) {
    _communities.removeWhere((c) => c.communityId == id);
  }
}
