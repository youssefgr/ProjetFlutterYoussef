class AnimeReminder {
  final int id;
  final String title;
  final String? imageUrl;      
  final String? releaseDate;
  final String? description;

  AnimeReminder({
    required this.id,
    required this.title,
    this.imageUrl,
    this.releaseDate,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'releaseDate': releaseDate,
    'description': description,
  };

  factory AnimeReminder.fromJson(Map<String, dynamic> json) => AnimeReminder(
    id: json['id'],
    title: json['title'],
    imageUrl: json['imageUrl'],
    releaseDate: json['releaseDate'],
    description: json['description'],
  );
}
