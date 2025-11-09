import 'dart:convert';
import 'package:http/http.dart' as http;
import '/config/jikan_config.dart';

class JikanService {
  JikanService._internal();

  static final JikanService instance = JikanService._internal();

  final String _baseUrl = JikanConfig.instance.baseUrl;

  /// Fetch upcoming anime
  Future<List<Map<String, dynamic>>> fetchUpcomingAnime() async {
    final url = Uri.parse("$_baseUrl/seasons/upcoming");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> animeList = data['data'];

        return animeList.map((anime) {
          return {
            'id': anime['mal_id'],
            'title': anime['title'] ?? 'Unknown',
            'image': anime['images']?['jpg']?['large_image_url'],
            'type': anime['type'] ?? 'Unknown',
            'episodes': anime['episodes'] ?? 0,
            'airing_start': anime['aired']?['from'] ?? 'Unknown',
            'synopsis': anime['synopsis'] ?? 'No description available',
            'score': anime['score'] ?? 0.0,
          };
        }).toList();
      } else {
        print("Jikan API Error: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Jikan API Exception: $e");
      return [];
    }
  }

  /// Fetch single anime details by title (search in upcoming anime)
  Future<Map<String, dynamic>?> fetchAnimeDetails(String title) async {
    final animeList = await fetchUpcomingAnime();
    try {
      final anime = animeList.firstWhere(
            (anime) =>
        anime['title'].toString().toLowerCase() == title.toLowerCase(),
        orElse: () => {}, // return empty map instead of null
      );
      return anime.isNotEmpty ? anime : null; // convert empty map to null
    } catch (e) {
      return null;
    }
  }
}
