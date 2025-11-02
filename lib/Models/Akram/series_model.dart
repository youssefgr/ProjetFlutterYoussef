// series_model.dart
class Series {
  final int id;
  final String name;
  final String posterPath;
  final String overview;
  final String firstAirDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final String originalLanguage;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final String status;
  final List<String> genres;
  final String backdropPath;

  Series({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.overview,
    required this.firstAirDate,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.originalLanguage,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.status = '',
    this.genres = const [],
    this.backdropPath = '',
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      posterPath: json['poster_path'] ?? '',
      overview: json['overview'] ?? '',
      firstAirDate: json['first_air_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      popularity: (json['popularity'] ?? 0).toDouble(),
      originalLanguage: json['original_language'] ?? '',
      numberOfSeasons: json['number_of_seasons'] ?? 0,
      numberOfEpisodes: json['number_of_episodes'] ?? 0,
      status: json['status'] ?? '',
      genres: (json['genres'] as List<dynamic>?)
          ?.map((g) => g['name'] as String)
          .toList() ??
          [],
      backdropPath: json['backdrop_path'] ?? '',
    );
  }
}