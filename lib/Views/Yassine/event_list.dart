// File: lib/pages/EventListScreen.dart
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:projetflutteryoussef/viewModels/event_viewmodel.dart';
import '/Models/Yassine/event_name.dart';
import 'event_add.dart';
import 'event_edit.dart';
import 'event_delete.dart';
import '/services/tmdb_service.dart';
import '/services/jikan_service.dart';
import 'event_details.dart';
import 'upcoming_movies.dart';
import 'upcoming_anime_page.dart';

// --- IMPORTANT: choose one of the two imports below depending on file location ---
// If calendar_events_page.dart is in the SAME folder as this file:
import 'calendar_events_page.dart';

// OR, if calendar_events_page.dart is at lib/pages/calendar_events_page.dart (package import):
// import 'package:projetflutteryoussef/pages/calendar_events_page.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final EventViewModel _viewModel = EventViewModel();
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSorted = false;

  // Cache results
  final Map<String, Map<String, dynamic>?> _eventCache = {};

  @override
  void initState() {
    super.initState();
    _viewModel.onEventsUpdated = () => setState(() {});
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    await _viewModel.loadEvents();
    setState(() => _isLoading = false);
  }

  List<Event> get _filteredEvents {
    List<Event> filtered = _viewModel.events;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
              (e) => e.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_isSorted) {
      filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return filtered;
  }

  Future<void> _printPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.ListView.builder(
          itemCount: _filteredEvents.length,
          itemBuilder: (context, index) {
            final e = _filteredEvents[index];
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${index + 1}. ${e.title} (${e.type})',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
              ],
            );
          },
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event List'),
        actions: [
          // Sort icon
          IconButton(
            icon: Icon(_isSorted ? Icons.sort_by_alpha : Icons.sort),
            tooltip: _isSorted ? "Unsort" : "Sort by name",
            onPressed: () => setState(() => _isSorted = !_isSorted),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: _filteredEvents.isEmpty ? null : _printPdf,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: "View Calendar",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarEventsPage(viewModel: _viewModel),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Event",
            onPressed: () async {
              final newEvent = await Navigator.push<Event>(
                context,
                MaterialPageRoute(builder: (_) => const AddEventDialog()),
              );
              if (newEvent != null) {
                await _viewModel.addEvent(
                  newEvent,
                  fetchTMDB: newEvent.type == 'movie',
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.movie_creation_outlined),
            tooltip: "Upcoming Movies",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpcomingMoviesPage(viewModel: _viewModel),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.animation),
            tooltip: "Upcoming Anime",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UpcomingAnimePage(viewModel: _viewModel),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _filteredEvents.isEmpty
          ? const Center(child: Text('No events found'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return _buildEventTile(event);
        },
      ),
    );
  }

  Widget _buildEventTile(Event event) {
    if (_eventCache.containsKey(event.title)) {
      return _buildEventCard(event, _eventCache[event.title]);
    }

    if (event.type == 'movie') {
      return FutureBuilder<Map<String, dynamic>?>(
        future: TMDBService.instance.fetchMovieDetails(event.title),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              title: Text(event.title),
              subtitle: const Text("Loading..."),
            );
          }

          final movie = snapshot.data;
          _eventCache[event.title] = movie;
          return _buildEventCard(event, movie);
        },
      );
    } else {
      return FutureBuilder<Map<String, dynamic>?>(
        future: JikanService.instance.fetchAnimeDetails(event.title),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              title: Text(event.title),
              subtitle: const Text("Loading..."),
            );
          }

          final anime = snapshot.data;
          _eventCache[event.title] = anime;
          return _buildEventCard(event, anime);
        },
      );
    }
  }

  Widget _buildEventCard(Event event, Map<String, dynamic>? data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreen(
                event: event,
                data: data,
              ),
            ),
          );
        },
        leading: data != null
            ? Image.network(
          event.type == 'movie'
              ? "https://image.tmdb.org/t/p/w200${data['poster_path']}"
              : data['image'] ?? '',
          width: 50,
          fit: BoxFit.cover,
        )
            : null,
        title: Text(data != null ? data['title'] ?? event.title : event.title),
        subtitle: data != null
            ? Text(
          event.type == 'movie'
              ? "${data['release_date'] ?? ''}\n${data['overview'] ?? ''}"
              : "${data['airing_start'] ?? ''}\n${data['synopsis'] ?? ''}",
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedEvent = await Navigator.push<Event>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditEventDialog(event: event)),
                );
                if (updatedEvent != null) {
                  await _viewModel.updateEvent(updatedEvent);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => EventDeleteDialog(
                    event: event,
                    onDelete: () async {
                      await _viewModel.deleteEvent(event.id);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
