import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/maamoune/message.dart';

class MessageRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send a message
  Future<void> sendMessage(Message message) async {
    try {
      print('📨 Sending message from ${message.senderId} to ${message.receiverId}');
      await _supabase.from('messages').insert(message.toMap());
      print('✅ Message sent successfully');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get conversation between two users
  Future<List<Message>> getConversation(String userId, String friendId) async {
    try {
      print('💬 Fetching conversation between $userId and $friendId');
      final response = await _supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .or('sender_id.eq.$friendId,receiver_id.eq.$friendId')
          .order('sent_at', ascending: true);

      final messages = (response as List)
          .map((data) => Message.fromMap(data))
          .where((msg) =>
      (msg.senderId == userId && msg.receiverId == friendId) ||
          (msg.senderId == friendId && msg.receiverId == userId))
          .toList();

      print('✅ Fetched ${messages.length} messages');
      return messages;
    } catch (e) {
      print('❌ Error fetching conversation: $e');
      throw Exception('Failed to fetch conversation: $e');
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String receiverId, String senderId) async {
    try {
      print('✅ Marking messages as read');
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('receiver_id', receiverId)
          .eq('sender_id', senderId)
          .eq('is_read', false);
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('receiver_id', userId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
      print('✅ Message deleted');
    } catch (e) {
      print('❌ Error deleting message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get last message with each friend
  Future<Map<String, Message>> getLastMessages(String userId, List<String> friendIds) async {
    try {
      final Map<String, Message> lastMessages = {};

      for (final friendId in friendIds) {
        final response = await _supabase
            .from('messages')
            .select()
            .or('sender_id.eq.$userId,receiver_id.eq.$userId')
            .or('sender_id.eq.$friendId,receiver_id.eq.$friendId')
            .order('sent_at', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          final msg = Message.fromMap(response[0]);
          if ((msg.senderId == userId && msg.receiverId == friendId) ||
              (msg.senderId == friendId && msg.receiverId == userId)) {
            lastMessages[friendId] = msg;
          }
        }
      }

      return lastMessages;
    } catch (e) {
      print('❌ Error getting last messages: $e');
      return {};
    }
  }
}
