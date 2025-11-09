import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';

class FriendshipRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CREATE - Send a friend request
  Future<void> sendFriendRequest(Friendship friendship) async {
    try {
      await _supabase.from('friendships').insert(friendship.toJson());
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  /// READ - Get all friendships
  Future<List<Friendship>> getAllFriendships() async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Friendship.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching friendships: $e');
      return [];
    }
  }

  /// READ - Get pending friend requests for a user (received requests)
  Future<List<Friendship>> getPendingRequests(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('friend_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Friendship.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching pending requests: $e');
      return [];
    }
  }

  /// READ - Get accepted friends of a user
  Future<List<Friendship>> getAcceptedFriends(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      final allAccepted = (response as List)
          .map((data) => Friendship.fromJson(data))
          .toList();

      return allAccepted
          .where((f) => f.userId == userId || f.friendId == userId)
          .toList();
    } catch (e) {
      print('Error fetching accepted friends: $e');
      return [];
    }
  }

  /// READ - Get sent friend requests (pending requests sent by user)
  Future<List<Friendship>> getSentRequests(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('user_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Friendship.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching sent requests: $e');
      return [];
    }
  }

  /// READ - Get blocked users
  Future<List<Friendship>> getBlockedUsers(String userId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('user_id', userId)
          .eq('status', 'blocked')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Friendship.fromJson(data))
          .toList();
    } catch (e) {
      print('Error fetching blocked users: $e');
      return [];
    }
  }

  /// READ - Get specific friendship by ID
  Future<Friendship?> getFriendshipById(String friendshipId) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select()
          .eq('friendship_id', friendshipId)
          .maybeSingle();

      if (response == null) return null;
      return Friendship.fromJson(response);
    } catch (e) {
      print('Error fetching friendship: $e');
      return null;
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
      print('Error accepting friend request: $e');
      rethrow;
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
      print('Error updating friendship status: $e');
      rethrow;
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
      print('Error blocking user: $e');
      rethrow;
    }
  }

  /// UPDATE - Unblock a user
  Future<void> unblockUser(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'pending'})
          .eq('friendship_id', friendshipId);
    } catch (e) {
      print('Error unblocking user: $e');
      rethrow;
    }
  }

  /// DELETE - Remove a friendship
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('friendship_id', friendshipId);
    } catch (e) {
      print('Error deleting friendship: $e');
      rethrow;
    }
  }
}
