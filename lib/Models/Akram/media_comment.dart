class MediaComment {
  final String id;
  final String mediaItemId;
  final String mediaTitle;  // Add this
  final String userId;
  final String userName;
  final DateTime date;
  final double rating;
  final String text;

  MediaComment({
    required this.id,
    required this.mediaItemId,
    required this.mediaTitle,  // Add this
    required this.userId,
    required this.userName,
    required this.date,
    required this.rating,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'media_item_id': mediaItemId,
      'media_title': mediaTitle,  // Add this
      'user_id': userId,
      'user_name': userName,
      'created_at': date.toIso8601String(),
      'rating': rating,
      'text': text,
    };
  }

  factory MediaComment.fromMap(Map<String, dynamic> map) {
    return MediaComment(
      id: map['id'],
      mediaItemId: map['media_item_id'],
      mediaTitle: map['media_title'],  // Add this
      userId: map['user_id'],
      userName: map['user_name'],
      date: DateTime.parse(map['created_at']),
      rating: (map['rating'] as num).toDouble(),
      text: map['text'],
    );
  }

  MediaComment copyWith({
    String? id,
    String? mediaItemId,
    String? mediaTitle,  // Add this
    String? userId,
    String? userName,
    DateTime? date,
    double? rating,
    String? text,
  }) {
    return MediaComment(
      id: id ?? this.id,
      mediaItemId: mediaItemId ?? this.mediaItemId,
      mediaTitle: mediaTitle ?? this.mediaTitle,  // Add this
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      rating: rating ?? this.rating,
      text: text ?? this.text,
    );
  }
}