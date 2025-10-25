class MediaComment {
  final String id;
  final String itemId;
  final String userId;
  final DateTime date;
  final double starRating;
  final String text;

  MediaComment({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.date,
    required this.starRating,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'starRating': starRating,
      'text': text,
    };
  }

  factory MediaComment.fromMap(Map<String, dynamic> map) {
    return MediaComment(
      id: map['id'],
      itemId: map['itemId'],
      userId: map['userId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      starRating: map['starRating'].toDouble(),
      text: map['text'],
    );
  }

  MediaComment copyWith({
    String? id,
    String? itemId,
    String? userId,
    DateTime? date,
    double? starRating,
    String? text,
  }) {
    return MediaComment(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      starRating: starRating ?? this.starRating,
      text: text ?? this.text,
    );
  }
}