import '/Models/Yassine/event_name.dart';
import '/repositories/Yassine/event_repository.dart';
import '/services/Yassine/tmdb_service.dart';

class EventViewModel {
  List<Event> _events = [];
  List<Event> get events => _events;

  Function()? onEventsUpdated;

  /// Load events from repository
  Future<void> loadEvents() async {
    _events = await EventRepository.loadEvents();
    onEventsUpdated?.call();
  }

  /// Add a new event manually or fetch TMDB data if type is 'movie'
  Future<void> addEvent(Event event, {bool fetchTMDB = true}) async {
    Event newEvent = event;

    if (fetchTMDB && event.type == 'movie') {
      final tmdbData = await TMDBService.instance.fetchMovieDetails(event.title);
      if (tmdbData != null) {
        newEvent = event.copyWith(
          posterUrl: tmdbData['poster_path'],
          overview: tmdbData['overview'],
          releaseDate: tmdbData['release_date'],
        );
      }
    }

    _events.add(newEvent);
    await EventRepository.saveEvents(_events);
    onEventsUpdated?.call();
  }

  /// Add an event directly from data (used for notification button)
  Future<void> addEventFromData({
    required String title,
    required String type, // 'movie' or 'anime'
    String? posterUrl,
    String? overview,
    String? releaseDate,
  }) async {
    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: type,
      posterUrl: posterUrl,
      overview: overview,
      releaseDate: releaseDate,
    );

    _events.add(newEvent);
    await EventRepository.saveEvents(_events);
    onEventsUpdated?.call();
  }

  /// Update an existing event
  Future<void> updateEvent(Event updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      await EventRepository.saveEvents(_events);
      onEventsUpdated?.call();
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await EventRepository.saveEvents(_events);
    onEventsUpdated?.call();
  }
}
