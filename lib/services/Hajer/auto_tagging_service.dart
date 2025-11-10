import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AutoTaggingService {
  final String apiUrl = "https://api-inference.huggingface.co/models/google/vit-base-patch16-224";
  final String? apiKey; // optionnel

  AutoTaggingService({this.apiKey});

  Future<List<String>> analyzeImage(Uint8List bytes) async {
    try {
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/octet-stream',
      };

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: bytes,
      );

      if (res.statusCode == 200) {
        final List<dynamic> output = jsonDecode(res.body);
        return output.map((e) => e['label'].toString()).take(5).toList();
      } else {
        return ["unknown"];
      }
    } catch (e) {
      return ["error: $e"];
    }
  }
}
