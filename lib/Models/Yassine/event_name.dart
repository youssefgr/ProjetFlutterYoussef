class Event {
  final String id;
  final String title;        // movie or anime title
  final String type;         // 'movie' or 'anime'
  final String? posterUrl;
  final String? overview;
  final String? releaseDate;

  Event({
    required this.id,
    required this.title,
    required this.type,
    this.posterUrl,
    this.overview,
    this.releaseDate,
  });

  Event copyWith({
    String? title,
    String? type,
    String? posterUrl,
    String? overview,
    String? releaseDate,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      posterUrl: posterUrl ?? this.posterUrl,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'posterUrl': posterUrl,
    'overview': overview,
    'releaseDate': releaseDate,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    posterUrl: json['posterUrl'],
    overview: json['overview'],
    releaseDate: json['releaseDate'],
  );
}
