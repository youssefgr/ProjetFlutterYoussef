import 'package:flutter/material.dart';
import '/Models/Yassine/event_name.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;
  final Map<String, dynamic>? data;

  const EventDetailScreen({super.key, required this.event, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: data == null
          ? Center(
        child: Text("No data available for ${event.title}"),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.posterUrl != null)
              Center(
                child: Image.network(
                  event.posterUrl!,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              event.title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Type: ${event.type}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Release Date: ${event.releaseDate ?? 'N/A'}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              event.overview ?? 'No overview available.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
