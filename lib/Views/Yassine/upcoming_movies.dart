import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '/services/Yassine/tmdb_service.dart';
import '/viewModels/Yassine/event_viewmodel.dart';
import '/Models/Yassine/event_name.dart';

class UpcomingMoviesPage extends StatefulWidget {
  final EventViewModel viewModel;
  const UpcomingMoviesPage({super.key, required this.viewModel});

  @override
  State<UpcomingMoviesPage> createState() => _UpcomingMoviesPageState();
}

class _UpcomingMoviesPageState extends State<UpcomingMoviesPage> {
  List<Map<String, dynamic>> _upcomingMovies = [];
  bool _isLoading = true;
  final Set<int> _reminderIds = {};

  @override
  void initState() {
    super.initState();
    _loadUpcomingMovies();
  }

  Future<void> _loadUpcomingMovies() async {
    setState(() => _isLoading = true);
    final movies = await TMDBService.instance.fetchUpcomingMovies();
    setState(() {
      _upcomingMovies = movies;
      _isLoading = false;
    });
  }

  Future<void> _setReminder(Map<String, dynamic> movie) async {
    final id = movie['id'] as int;
    final releaseDateStr = movie['release_date'];
    if (releaseDateStr == null) return;

    final releaseDate = DateTime.tryParse(releaseDateStr);
    if (releaseDate == null) return;

    setState(() {
      if (_reminderIds.contains(id)) {
        _reminderIds.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reminder removed")),
        );
        AwesomeNotifications().cancel(id);
      } else {
        _reminderIds.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reminder set")),
        );

        // Schedule notification
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id,
            channelKey: 'release_reminders',
            title: 'Movie Release Reminder',
            body: 'The movie is releasing today: ${movie['title']}',
            notificationLayout: NotificationLayout.Default,
          ),
          schedule: NotificationCalendar.fromDate(date: releaseDate),
        );

        // Add to event list
        final newEvent = Event(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: movie['title'] ?? 'Unknown',
          type: 'movie',
          posterUrl: movie['poster_path'],
          overview: movie['overview'],
          releaseDate: releaseDateStr,
        );
        widget.viewModel.addEvent(newEvent, fetchTMDB: true);
      }
    });
  }

  void _showMovieDetails(Map<String, dynamic> movie) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(movie['title'] ?? 'Unknown'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (movie['poster_path'] != null)
                Image.network(
                  "https://image.tmdb.org/t/p/w300${movie['poster_path']}",
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 8),
              Text("Release Date: ${movie['release_date'] ?? 'Unknown'}"),
              const SizedBox(height: 8),
              Text(movie['overview'] ?? 'No description available'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Movies')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _upcomingMovies.isEmpty
          ? const Center(child: Text('No upcoming movies found'))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: _upcomingMovies.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          itemBuilder: (context, index) {
            final movie = _upcomingMovies[index];
            final isReminderSet = _reminderIds.contains(movie['id']);

            return GestureDetector(
              onTap: () => _showMovieDetails(movie),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: movie['poster_path'] != null
                              ? Image.network(
                            "https://image.tmdb.org/t/p/w300${movie['poster_path']}",
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.movie, size: 50),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie['title'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                movie['release_date'] ?? '',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                        Colors.black.withOpacity(0.6),
                        child: IconButton(
                          icon: Icon(
                            isReminderSet
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            size: 18,
                            color: isReminderSet
                                ? Colors.greenAccent
                                : Colors.white,
                          ),
                          onPressed: () => _setReminder(movie),
                          tooltip: isReminderSet
                              ? "Remove Reminder"
                              : "Set Reminder",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
