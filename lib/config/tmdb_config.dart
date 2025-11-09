class TMDBConfig {
  // Private constructor
  TMDBConfig._privateConstructor();

  // Singleton instance
  static final TMDBConfig _instance = TMDBConfig._privateConstructor();

  // Getter to access the singleton
  static TMDBConfig get instance => _instance;

  // TMDB API key (replace with your actual key)
  final String apiKey = "2c26e33bfc5b900a3afe547a2d95c6b0";

  // Base URL for TMDB API v3
  final String baseUrl = "https://api.themoviedb.org/3";

  // Image base URLs (from TMDB configuration)
  final String imageBaseUrl = "https://image.tmdb.org/t/p/";
  final String posterSize = "w500"; // You can change this to w200, w300, etc.
  final String backdropSize = "w780";

  // Example helper method to get full poster URL
  String getPosterUrl(String path) => "$imageBaseUrl$posterSize$path";

  // Example helper method to get full backdrop URL
  String getBackdropUrl(String path) => "$imageBaseUrl$backdropSize$path";
}
