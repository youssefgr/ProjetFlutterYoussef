class Message {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  /// Convert to map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': messageId,
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Create from Supabase map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['id'] ?? map['message_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      content: map['content'] ?? '',
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'])
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
    );
  }

  /// Copy with changes
  Message copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'Message(id: $messageId, from: $senderId, to: $receiverId)';
  }
}
