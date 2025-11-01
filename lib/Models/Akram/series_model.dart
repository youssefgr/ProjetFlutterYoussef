class Series {
  final int id;
  final String name;
  final String posterPath;

  Series({
    required this.id,
    required this.name,
    required this.posterPath,
  });

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      posterPath: json['poster_path'] ?? '',
    );
  }
}