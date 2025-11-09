import 'package:projetflutteryoussef/Models/maamoune/community.dart';

class CommunityRepository {
  final List<Community> _communities = [];

  // CREATE
  Future<void> createCommunity(Community community) async {
    _communities.add(community);
  }

  // READ
  Future<List<Community>> getAllCommunities() async {
    return List.unmodifiable(_communities);
  }

  Future<Community?> getCommunityById(String id) async {
    try {
      return _communities.firstWhere((c) => c.communityId == id);
    } catch (e) {
      return null;
    }
  }

  // Get communities a user has joined
  Future<List<Community>> getCommunitiesByUserId(String userId) async {
    return _communities
        .where((c) => c.isMember(userId))
        .toList();
  }

  // UPDATE
  Future<void> updateCommunity(Community updatedCommunity) async {
    final index = _communities.indexWhere((c) => c.communityId == updatedCommunity.communityId);
    if (index != -1) {
      _communities[index] = updatedCommunity;
    }
  }

  // Join community
  Future<void> joinCommunity(String communityId, String userId) async {
    final community = await getCommunityById(communityId);
    if (community != null && !community.isMember(userId)) {
      final updatedMembers = [...community.memberIds, userId];
      await updateCommunity(community.copyWith(memberIds: updatedMembers));
    }
  }

  // Leave community
  Future<void> leaveCommunity(String communityId, String userId) async {
    final community = await getCommunityById(communityId);
    if (community != null && !community.isOwner(userId)) {
      final updatedMembers = community.memberIds.where((id) => id != userId).toList();
      final updatedAdmins = community.adminIds.where((id) => id != userId).toList();
      await updateCommunity(community.copyWith(
        memberIds: updatedMembers,
        adminIds: updatedAdmins,
      ));
    }
  }

  // Make user admin
  Future<void> promoteToAdmin(String communityId, String userId) async {
    final community = await getCommunityById(communityId);
    if (community != null && !community.isAdmin(userId)) {
      final updatedAdmins = [...community.adminIds, userId];
      await updateCommunity(community.copyWith(adminIds: updatedAdmins));
    }
  }

  // Remove admin role
  Future<void> demoteFromAdmin(String communityId, String userId) async {
    final community = await getCommunityById(communityId);
    if (community != null && !community.isOwner(userId)) {
      final updatedAdmins = community.adminIds.where((id) => id != userId).toList();
      await updateCommunity(community.copyWith(adminIds: updatedAdmins));
    }
  }

  // DELETE
  Future<void> deleteCommunity(String id) async {
    _communities.removeWhere((c) => c.communityId == id);
  }
}
