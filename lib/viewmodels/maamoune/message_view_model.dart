import 'package:flutter/foundation.dart';
import 'package:projetflutteryoussef/Models/maamoune/message.dart';
import 'package:projetflutteryoussef/repositories/maamoune/message_repository.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageRepository _repo = MessageRepository();

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  /// Send a message
  Future<void> sendMessage(Message message) async {
    try {
      print('📨 Sending message...');
      await _repo.sendMessage(message);

      // Add to local list immediately
      _messages.add(message);
      notifyListeners();

      _error = null;
      print('✅ Message sent');
    } catch (e) {
      _error = 'Failed to send message: $e';
      print('❌ Error: $_error');
    }
  }

  /// Load conversation
  Future<void> loadConversation(String userId, String friendId) async {
    _setLoading(true);
    try {
      print('💬 Loading conversation...');
      _messages = await _repo.getConversation(userId, friendId);

      // Mark messages as read
      await _repo.markAsRead(userId, friendId);

      _error = null;
      print('✅ Loaded ${_messages.length} messages');
    } catch (e) {
      _error = 'Failed to load conversation: $e';
      print('❌ Error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh conversation (polling)
  Future<void> refreshConversation(String userId, String friendId) async {
    try {
      _messages = await _repo.getConversation(userId, friendId);
      await _repo.markAsRead(userId, friendId);
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing: $e');
    }
  }

  /// Load unread count
  Future<void> loadUnreadCount(String userId) async {
    try {
      _unreadCount = await _repo.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      print('❌ Error loading unread count: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _repo.deleteMessage(messageId);
      _messages.removeWhere((m) => m.messageId == messageId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete message: $e';
      print('❌ Error: $_error');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear messages
  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  /// Private helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
