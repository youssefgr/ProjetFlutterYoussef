import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:projetflutteryoussef/Models/maamoune/community.dart';
import 'package:projetflutteryoussef/repositories/maamoune/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository = CommunityRepository();
  late SupabaseClient _supabase;

  List<Community> _communities = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Community> get communities => _communities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CommunityViewModel() {
    _supabase = Supabase.instance.client;
  }

  // Fetch all communities
  Future<void> fetchCommunities() async {
    _setLoading(true);
    try {
      _communities = await _repository.getAllCommunities();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch communities: $e';
      print('❌ Error fetching communities: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Join a community
  Future<void> joinCommunity(String communityId, String userId) async {
    _setLoading(true);
    try {
      print('👥 Joining community: $communityId');
      await _repository.joinCommunity(communityId, userId);
      await fetchCommunities();
      _error = null;
      print('✅ Joined community successfully');
    } catch (e) {
      _error = 'Failed to join community: $e';
      print('❌ Error joining community: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Leave a community
  Future<void> leaveCommunity(String communityId, String userId) async {
    _setLoading(true);
    try {
      print('👋 Leaving community: $communityId');
      await _repository.leaveCommunity(communityId, userId);
      await fetchCommunities();
      _error = null;
      print('✅ Left community successfully');
    } catch (e) {
      _error = 'Failed to leave community: $e';
      print('❌ Error leaving community: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Rename a community (admin only)
  Future<void> renameCommunity(String communityId, String newName) async {
    _setLoading(true);
    try {
      print('📝 Renaming community: $communityId to $newName');
      await _repository.updateCommunity(communityId, {'name': newName});

      // Update locally
      final index = _communities.indexWhere((c) => c.communityId == communityId);
      if (index != -1) {
        _communities[index] = _communities[index].copyWith(name: newName);
      }

      _error = null;
      notifyListeners();
      print('✅ Community renamed successfully');
    } catch (e) {
      _error = 'Failed to rename community: $e';
      print('❌ Error renaming community: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Change member role (admin only)
  Future<void> changeMemberRole(String communityId, String userId, String newRole) async {
    _setLoading(true);
    try {
      print('👤 Changing role for $userId in community $communityId to $newRole');
      await _repository.changeMemberRole(communityId, userId, newRole);
      await fetchCommunities();
      _error = null;
      print('✅ Member role changed successfully');
    } catch (e) {
      _error = 'Failed to change member role: $e';
      print('❌ Error changing member role: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Remove member from community (admin only)
  Future<void> removeMember(String communityId, String userId) async {
    _setLoading(true);
    try {
      print('🚫 Removing member $userId from community $communityId');
      await _repository.removeMember(communityId, userId);
      await fetchCommunities();
      _error = null;
      print('✅ Member removed successfully');
    } catch (e) {
      _error = 'Failed to remove member: $e';
      print('❌ Error removing member: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
