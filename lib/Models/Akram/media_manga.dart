class Manga {
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

  Manga({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.overview,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.originalLanguage,
    required this.runtime,
    required this.genres,
    required this.backdropPath,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;

    // Extract values with proper null handling
    final dynamic meanValue = node['mean'];
    final dynamic numListUsersValue = node['num_list_users'];
    final dynamic popularityValue = node['popularity'];
    final dynamic numChaptersValue = node['num_chapters'];

    // Convert to proper types with null safety
    final double voteAverage = (meanValue is num ? meanValue.toDouble() : 0.0);
    final int voteCount = (numListUsersValue is int ? numListUsersValue : 0);
    final double popularity = (popularityValue is num ? popularityValue.toDouble() : 0.0);
    final int runtime = (numChaptersValue is int ? numChaptersValue : 0);

    return Manga(
      id: (node['id'] is int ? node['id'] : 0) as int,
      title: (node['title'] as String? ?? ''),
      posterPath: (node['main_picture']?['medium'] as String? ?? ''),
      overview: (node['synopsis'] as String? ?? ''),
      releaseDate: (node['start_date'] as String? ?? ''),
      voteAverage: voteAverage,
      voteCount: voteCount,
      popularity: popularity,
      originalLanguage: 'ja',
      runtime: runtime,
      genres: (node['genres'] is List
          ? (node['genres'] as List).map((g) => (g['name'] as String? ?? '')).where((name) => name.isNotEmpty).toList()
          : <String>[]),
      backdropPath: (node['main_picture']?['large'] as String? ?? ''),
    );
  }
}