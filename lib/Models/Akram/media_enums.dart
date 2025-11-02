enum MediaCategory {
  anime,
  film,
  manga,
  series,
}

enum MediaViewStatus {
  toView,
  viewing,
  viewed,
}

enum MediaGenre {
  action,
  adventure,
  animation,
  comedy,
  crime,
  documentary,
  drama,
  family,
  fantasy,
  history,
  horror,
  music,
  mystery,
  romance,
  scienceFiction,
  thriller,
  war,
  western,
}

class GenreMapper {
  static final Map<String, MediaGenre> genreMap = {
    'action': MediaGenre.action,
    'adventure': MediaGenre.adventure,
    'animation': MediaGenre.animation,
    'comedy': MediaGenre.comedy,
    'crime': MediaGenre.crime,
    'documentary': MediaGenre.documentary,
    'drama': MediaGenre.drama,
    'family': MediaGenre.family,
    'fantasy': MediaGenre.fantasy,
    'history': MediaGenre.history,
    'horror': MediaGenre.horror,
    'music': MediaGenre.music,
    'mystery': MediaGenre.mystery,
    'romance': MediaGenre.romance,
    'science fiction': MediaGenre.scienceFiction,
    'sci-fi': MediaGenre.scienceFiction,
    'sciencefiction': MediaGenre.scienceFiction,
    'thriller': MediaGenre.thriller,
    'war': MediaGenre.war,
    'western': MediaGenre.western,
  };

  static MediaGenre autoDetectGenre(List<String> genres) {
    if (genres.isEmpty) return MediaGenre.action;

    // Check each genre in order and return the first match
    for (final genre in genres) {
      final lowerGenre = genre.toLowerCase();
      for (final entry in genreMap.entries) {
        if (lowerGenre.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    // Fallback to action if no match found
    return MediaGenre.action;
  }

  static String formatEnumName(String enumName) {
    // Convert camelCase to Title Case with spaces
    return enumName
        .replaceAllMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase())
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .trim();
  }
}