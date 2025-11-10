import 'dart:convert';
import 'package:http/http.dart' as http;
import '/config/tmdb_config.dart';

class TMDBService {
  TMDBService._privateConstructor();
  static final TMDBService instance = TMDBService._privateConstructor();

  /// Search a movie by name
  Future<Map<String, dynamic>?> fetchMovieDetails(String name) async {
    final apiKey = TMDBConfig.instance.apiKey;
    final baseUrl = TMDBConfig.instance.baseUrl;

    final url = Uri.parse(
        "$baseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(name)}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final firstResult = Map<String, dynamic>.from(data['results'][0]);

          // Add media_type if missing
          if (!firstResult.containsKey('media_type')) {
            firstResult['media_type'] = 'unknown';
          }

          return firstResult;
        }
      } else {
        print("TMDB API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("TMDB API Exception: $e");
    }

    return null;
  }


  /// Fetch list of upcoming content (movies + TV shows)
  Future<List<Map<String, dynamic>>> fetchUpcomingMovies() async {
    final apiKey = TMDBConfig.instance.apiKey;
    final baseUrl = TMDBConfig.instance.baseUrl;

    final movieUrl = Uri.parse("$baseUrl/movie/upcoming?api_key=$apiKey&language=en-US");

    List<Map<String, dynamic>> upcomingMovies = [];

    try {
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages && currentPage <= 10) { // limit for safety
        final url = Uri.parse("$baseUrl/movie/upcoming?api_key=$apiKey&language=en-US&page=$currentPage");
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = data['results'];

          if (results != null && results.isNotEmpty) {
            upcomingMovies.addAll(
              List<Map<String, dynamic>>.from(
                results.map((e) => {...Map<String, dynamic>.from(e), 'media_type': 'movie'}),
              ),
            );

            currentPage++;
            hasMorePages = currentPage <= (data['total_pages'] ?? 1);
          } else {
            hasMorePages = false;
          }
        } else {
          print("TMDB API Error (movies): ${response.statusCode}");
          hasMorePages = false;
        }
      }

      // Optional: sort by release date
      upcomingMovies.sort((b, a) {
        final dateA = DateTime.tryParse(a['release_date'] ?? '') ?? DateTime(2100);
        final dateB = DateTime.tryParse(b['release_date'] ?? '') ?? DateTime(2100);
        return dateA.compareTo(dateB);
      });

    } catch (e) {
      print("TMDB API Exception: $e");
    }

    return upcomingMovies;
  }

}
