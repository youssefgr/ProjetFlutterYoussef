import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/maamoune/community.dart';

class CommunityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all communities
  Future<List<Community>> getAllCommunities() async {
    try {
      final response = await _supabase.from('communities').select();
      return (response as List)
          .map((data) => Community.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Error fetching communities: $e');
    }
  }

  /// Get community by ID
  Future<Community?> getCommunityById(String communityId) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .eq('id', communityId)
          .maybeSingle();

      if (response == null) return null;
      return Community.fromMap(response);
    } catch (e) {
      throw Exception('Error fetching community: $e');
    }
  }

  /// Join community
  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      // Get current community data
      final community = await getCommunityById(communityId);
      if (community == null) throw Exception('Community not found');

      // Add user to memberIds array
      final updatedMembers = [...community.memberIds, userId];

      await _supabase
          .from('communities')
          .update({'member_ids': updatedMembers})
          .eq('id', communityId);
    } catch (e) {
      throw Exception('Error joining community: $e');
    }
  }

  /// Leave community
  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      // Get current community data
      final community = await getCommunityById(communityId);
      if (community == null) throw Exception('Community not found');

      // Remove user from memberIds array
      final updatedMembers = community.memberIds.where((id) => id != userId).toList();

      // Also remove from admins if they are
      final updatedAdmins = community.adminIds.where((id) => id != userId).toList();

      await _supabase
          .from('communities')
          .update({
        'member_ids': updatedMembers,
        'admin_ids': updatedAdmins,
      })
          .eq('id', communityId);
    } catch (e) {
      throw Exception('Error leaving community: $e');
    }
  }

  /// Update community (rename, etc.)
  Future<void> updateCommunity(String communityId, Map<String, dynamic> updates) async {
    try {
      print('📝 Updating community $communityId with: $updates');
      await _supabase
          .from('communities')
          .update(updates)
          .eq('id', communityId);
      print('✅ Community updated successfully');
    } catch (e) {
      throw Exception('Error updating community: $e');
    }
  }

  /// Change member role (admin/member)
  Future<void> changeMemberRole(String communityId, String userId, String newRole) async {
    try {
      final community = await getCommunityById(communityId);
      if (community == null) throw Exception('Community not found');

      var updatedAdmins = List<String>.from(community.adminIds);

      if (newRole.toLowerCase() == 'admin') {
        // Add to admins if not already
        if (!updatedAdmins.contains(userId)) {
          updatedAdmins.add(userId);
        }
      } else {
        // Remove from admins
        updatedAdmins.remove(userId);
      }

      await _supabase
          .from('communities')
          .update({'admin_ids': updatedAdmins})
          .eq('id', communityId);
    } catch (e) {
      throw Exception('Error changing member role: $e');
    }
  }

  /// Remove member from community
  Future<void> removeMember(String communityId, String userId) async {
    try {
      final community = await getCommunityById(communityId);
      if (community == null) throw Exception('Community not found');

      // Remove from members and admins
      final updatedMembers = community.memberIds.where((id) => id != userId).toList();
      final updatedAdmins = community.adminIds.where((id) => id != userId).toList();

      await _supabase
          .from('communities')
          .update({
        'member_ids': updatedMembers,
        'admin_ids': updatedAdmins,
      })
          .eq('id', communityId);
    } catch (e) {
      throw Exception('Error removing member: $e');
    }
  }

  /// Create a new community
  Future<Community> createCommunity({
    required String name,
    required String creatorId,
    String? description,
  }) async {
    try {
      print('🆕 Creating community: $name');
      final communityId = DateTime.now().millisecondsSinceEpoch.toString();

      await _supabase.from('communities').insert({
        'id': communityId,
        'name': name,
        'description': description ?? '',
        'member_ids': [creatorId],
        'admin_ids': [creatorId],
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Community created successfully');
      return Community(
        communityId: communityId,
        name: name,
        description: description,
        memberIds: [creatorId],
        adminIds: [creatorId],
      );
    } catch (e) {
      throw Exception('Error creating community: $e');
    }
  }
}
