
// movie_model.dart
class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String overview;
  final String releaseDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final String originalLanguage;
  final int runtime;
  final List<String> genres;
  final String backdropPath;

  Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.originalLanguage,
    this.runtime = 0,
    this.genres = const [],
    this.backdropPath = '',
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      originalLanguage: json['original_language'] ?? '',
      runtime: json['runtime'] ?? 0,
      genres: (json['genres'] as List<dynamic>?)
          ?.map((g) => g['name'] as String)
          .toList() ??
          [],
      backdropPath: json['backdrop_path'] ?? '',
    );
  }
}