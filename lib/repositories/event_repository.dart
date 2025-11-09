import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../Models/Yassine/event_name.dart';
import 'package:flutter/foundation.dart';

class EventRepository {
  static const String _fileName = 'events_data.json';

  // Get the local file
  static Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  // Save events to file
  static Future<void> saveEvents(List<Event> events) async {
    try {
      final file = await _getLocalFile();
      final jsonList = events.map((e) => _eventToJson(e)).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) print('Error saving events: $e');
    }
  }

  // Load events from file
  static Future<List<Event>> loadEvents() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonList = jsonDecode(jsonString) as List;
        return jsonList.map((json) => _eventFromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading events: $e');
    }
    return [];
  }

  // Convert Event to JSON
  static Map<String, dynamic> _eventToJson(Event event) => event.toJson();

  // Convert JSON to Event
  static Event _eventFromJson(Map<String, dynamic> json) => Event.fromJson(json);
}
