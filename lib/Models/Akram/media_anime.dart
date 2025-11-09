class Anime {
  final int id;
  final String title;
  final String posterPath;
  final String synopsis;
  final String startDate;
  final double mean;
  final int ranking;
  final List<String> genres;
  final List<String> studios;
  final String status; // ADD THIS

  Anime({
    required this.id,
    required this.title,
    required this.posterPath,
    this.synopsis = '',
    this.startDate = '',
    this.mean = 0.0,
    this.ranking = 0,
    this.genres = const [],
    this.studios = const [],
    this.status = '', // ADD THIS
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;
    return Anime(
      id: node['id'] ?? 0,
      title: node['title'] ?? '',
      posterPath: node['main_picture']?['medium'] ?? '',
      synopsis: node['synopsis'] ?? '',
      startDate: node['start_date'] ?? '',
      mean: (node['mean'] ?? 0).toDouble(),
      ranking: json['ranking']?['rank'] ?? 0,
      genres: (node['genres'] as List<dynamic>?)
          ?.map((g) => g['name'] as String)
          .toList() ??
          [],
      studios: (node['studios'] as List<dynamic>?)
          ?.map((s) => s['name'] as String)
          .toList() ??
          [],
      status: node['status'] ?? '', // ADD THIS
    );
  }
}