class MediaComment {
  final String id;
  final String mediaItemId;
  final String userId;
  final String userName;
  final DateTime date;
  final double rating;
  final String text;

  MediaComment({
    required this.id,
    required this.mediaItemId,
    required this.userId,
    required this.userName,
    required this.date,
    required this.rating,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaItemId': mediaItemId,
      'userId': userId,
      'userName': userName,
      'date': date.millisecondsSinceEpoch,
      'rating': rating,
      'text': text,
    };
  }

  factory MediaComment.fromMap(Map<String, dynamic> map) {
    return MediaComment(
      id: map['id'],
      mediaItemId: map['mediaItemId'],
      userId: map['userId'],
      userName: map['userName'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      rating: map['rating'].toDouble(),
      text: map['text'],
    );
  }

  MediaComment copyWith({
    String? id,
    String? mediaItemId,
    String? userId,
    String? userName,
    DateTime? date,
    double? rating,
    String? text,
  }) {
    return MediaComment(
      id: id ?? this.id,
      mediaItemId: mediaItemId ?? this.mediaItemId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      rating: rating ?? this.rating,
      text: text ?? this.text,
    );
  }
}