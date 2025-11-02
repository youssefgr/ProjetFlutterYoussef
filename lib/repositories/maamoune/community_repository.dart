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
    try {
      return _communities.firstWhere((c) => c.communityId == id);
    } catch (e) {
      return null;
    }
  }

  // Get communities a user has joined
  List<Community> getCommunitiesByUserId(String userId) {
    return _communities
        .where((c) => c.isMember(userId))
        .toList();
  }

  // UPDATE
  void updateCommunity(Community updatedCommunity) {
    final index = _communities.indexWhere((c) => c.communityId == updatedCommunity.communityId);
    if (index != -1) {
      _communities[index] = updatedCommunity;
    }
  }

  // Join community
  void joinCommunity(String communityId, String userId) {
    final community = getCommunityById(communityId);
    if (community != null && !community.isMember(userId)) {
      final updatedMembers = [...community.memberIds, userId];
      updateCommunity(community.copyWith(memberIds: updatedMembers));
    }
  }

  // Leave community
  void leaveCommunity(String communityId, String userId) {
    final community = getCommunityById(communityId);
    if (community != null && !community.isOwner(userId)) {
      final updatedMembers = community.memberIds.where((id) => id != userId).toList();
      final updatedAdmins = community.adminIds.where((id) => id != userId).toList();
      updateCommunity(community.copyWith(
        memberIds: updatedMembers,
        adminIds: updatedAdmins,
      ));
    }
  }

  // Make user admin
  void promoteToAdmin(String communityId, String userId) {
    final community = getCommunityById(communityId);
    if (community != null && !community.isAdmin(userId)) {
      final updatedAdmins = [...community.adminIds, userId];
      updateCommunity(community.copyWith(adminIds: updatedAdmins));
    }
  }

  // Remove admin role
  void demoteFromAdmin(String communityId, String userId) {
    final community = getCommunityById(communityId);
    if (community != null && !community.isOwner(userId)) {
      final updatedAdmins = community.adminIds.where((id) => id != userId).toList();
      updateCommunity(community.copyWith(adminIds: updatedAdmins));
    }
  }

  // DELETE
  void deleteCommunity(String id) {
    _communities.removeWhere((c) => c.communityId == id);
  }
}