import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class NotificationService {
  static const String _apiKey = '2c26e33bfc5b900a3afe547a2d95c6b0'; // Note: This appears to be a test key
  static const String _baseUrl = 'https://api.themoviedb.org/3'; // Fixed API base URL

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // use app icon
      [
        NotificationChannel(
          channelKey: 'recommendation_channel',
          channelName: 'Recommendations',
          channelDescription: 'Channel for media recommendations',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Color(0xFF9D50DD),
          importance: NotificationImportance.High,
        ),
      ],
    );

    // Ask for permission
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  /// 🔹 Fetch a random trending movie title from TMDB
  static Future<String?> fetchRandomMovieTitle() async {
    try {
      final url = Uri.parse('$_baseUrl/trending/movie/day?api_key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];
        if (results.isNotEmpty) {
          final shuffledResults = List.from(results)..shuffle();
          return shuffledResults.first['title'];
        }
      } else {
        print('TMDB API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching movie: $e');
    }
    return null;
  }

  static Future<void> showRecommendation(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'recommendation_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static void startPeriodicRecommendations() {
    Timer.periodic(const Duration(seconds: 20), (timer) async {
      final movieTitle = await fetchRandomMovieTitle();
      if (movieTitle != null) {
        await showRecommendation(
          "Today's Recommendation 🎬",
          "Watch \"$movieTitle\" tonight",
        );
      } else {
        // Fallback notification when movie fetch fails
        await showRecommendation(
          "Movie Recommendation 🎬",
          "Check out trending movies today!",
        );
      }
    });
  }
}