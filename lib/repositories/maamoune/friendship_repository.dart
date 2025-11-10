import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';

class FriendshipRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE - Send a friend request
  Future<void> sendFriendRequest(Friendship friendship) async {
    try {
      await _supabase.from('friendships').insert(friendship.toMap());
    } catch (e) {
      throw Exception('Failed to send friend request: $e');
    }
  }

  /// READ - Get all friendships
  Future<List<Friendship>> getAllFriendships() async {
    try {
      final response = await _supabase.from('friendships').select();
      return (response as List)
          .map((data) => Friendship.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch friendships: $e');
    }
  }

  /// READ - Get friendships for a specific user
  Future<List<Friendship>> getFriendshipsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .or('user_id.eq.$userId,friend_id.eq.$userId');
      return (response as List)
          .map((data) => Friendship.fromMap(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user friendships: $e');
    }
  }

  /// READ - Get specific friendship
  Future<Friendship?> getFriendshipById(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('friendship_id', friendshipId)
          .maybeSingle();

      if (response == null) return null;
      return Friendship.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get friendship: $e');
    }
  }

  /// UPDATE - Accept a friend request
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('friendship_id', friendshipId);
    } catch (e) {
      throw Exception('Failed to accept friend request: $e');
    }
  }

  /// UPDATE - Update friendship status
  Future<void> updateFriendshipStatus(String friendshipId, FriendshipStatus status) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': status.name})
          .eq('friendship_id', friendshipId);
    } catch (e) {
      throw Exception('Failed to update friendship status: $e');
    }
  }

  /// UPDATE - Block a user
  Future<void> blockUser(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'blocked'})
          .eq('friendship_id', friendshipId);
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// UPDATE - Unblock a user
  Future<void> unblockUser(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('friendship_id', friendshipId);
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// DELETE - Delete friendship
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('friendship_id', friendshipId);
    } catch (e) {
      throw Exception('Failed to delete friendship: $e');
    }
  }

  /// DELETE - Decline a friend request
  Future<void> declineFriendRequest(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('friendship_id', friendshipId);
    } catch (e) {
      throw Exception('Failed to decline friend request: $e');
    }
  }
}
