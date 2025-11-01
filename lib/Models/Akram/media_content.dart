import 'media_models.dart';

class MediaItem {
  final String id;
  final MediaCategory category;
  final String title;
  final String imageUrl;
  final DateTime releaseDate;
  final String description;
  final MediaViewStatus status;
  final List<MediaGenre> genres;
  final String userId;

  MediaItem({
    required this.id,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.releaseDate,
    required this.description,
    required this.status,
    required this.genres,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.index,
      'title': title,
      'posterUrl': imageUrl,
      'releaseDate': releaseDate.millisecondsSinceEpoch,
      'description': description,
      'status': status.index,
      'genres': genres.map((genre) => genre.index).toList(),
      'userId': userId,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'],
      category: MediaCategory.values[map['category']],
      title: map['title'],
      imageUrl: map['posterUrl'],
      releaseDate: DateTime.fromMillisecondsSinceEpoch(map['releaseDate']),
      description: map['description'],
      status: MediaViewStatus.values[map['status']],
      genres: (map['genres'] as List).map((index) => MediaGenre.values[index]).toList(),
      userId: map['userId'],
    );
  }

  MediaItem copyWith({
    String? id,
    MediaCategory? category,
    String? title,
    String? posterUrl,
    DateTime? releaseDate,
    String? description,
    MediaViewStatus? status,
    List<MediaGenre>? genres,
    String? userId,
  }) {
    return MediaItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      imageUrl: posterUrl ?? imageUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      description: description ?? this.description,
      status: status ?? this.status,
      genres: genres ?? this.genres,
      userId: userId ?? this.userId,
    );
  }
}