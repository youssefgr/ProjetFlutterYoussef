class Anime {
  final int id;
  final String title;
  final String posterPath;

  Anime({
    required this.id,
    required this.title,
    required this.posterPath,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;
    return Anime(
      id: node['id'] ?? 0,
      title: node['title'] ?? '',
      posterPath: node['main_picture']?['medium'] ?? '',
    );
  }
}