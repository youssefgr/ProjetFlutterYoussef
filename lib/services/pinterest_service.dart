// lib/services/pinterest_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PinterestService {
  static final String _accessToken = dotenv.env['PINTEREST_ACCESS_TOKEN'] ?? '';

  /// 🔍 Recherche d'images sur Pinterest
  static Future<List<PinterestPin>> searchImages(String query, {int count = 20}) async {
    try {
      if (_accessToken.isEmpty) {
        throw Exception('Token Pinterest manquant dans .env');
      }

      final response = await http.get(
        Uri.parse('https://api.pinterest.com/v5/search/pins?'
            'query=$query&page_size=$count'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];

        return items.map((item) => PinterestPin.fromJson(item)).toList();
      } else {
        throw Exception('Erreur Pinterest API: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur recherche Pinterest: $e');
      rethrow;
    }
  }

  /// ⬇️ Téléchargement d'une image depuis l'URL Pinterest
  static Future<Uint8List> downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Erreur téléchargement image: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Erreur download Pinterest: $e');
      rethrow;
    }
  }
}

/// 🧩 Modèle pour les pins Pinterest
class PinterestPin {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? creator;
  final String? sourceUrl;

  PinterestPin({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.creator,
    this.sourceUrl,
  });

  factory PinterestPin.fromJson(Map<String, dynamic> json) {
    final media = json['media'] ?? {};
    final images = media['images'] ?? {};
    final original = images['original'] ?? {};

    return PinterestPin(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sans titre',
      description: json['description'] ?? '',
      imageUrl: original['url'] ?? '',
      creator: json['creator']?['full_name'] ?? 'Unknown',
      sourceUrl: json['link'] ?? '',
    );
  }
}