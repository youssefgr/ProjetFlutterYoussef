// File: upcoming_anime_page.dart
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '/services/Yassine/jikan_service.dart';
import '/viewModels/Yassine/event_viewmodel.dart';
import '/Models/Yassine/event_name.dart';

class UpcomingAnimePage extends StatefulWidget {
  final EventViewModel viewModel;
  const UpcomingAnimePage({super.key, required this.viewModel});

  @override
  State<UpcomingAnimePage> createState() => _UpcomingAnimePageState();
}

class _UpcomingAnimePageState extends State<UpcomingAnimePage> {
  List<Map<String, dynamic>> _upcomingAnime = [];
  bool _isLoading = true;
  final Set<int> _reminderIds = {};

  @override
  void initState() {
    super.initState();
    _loadUpcomingAnime();
  }

  Future<void> _loadUpcomingAnime() async {
    setState(() {
      _isLoading = true;
    });
    final animeList = await JikanService.instance.fetchUpcomingAnime();
    setState(() {
      _upcomingAnime = animeList;
      _isLoading = false;
    });
  }

  Future<void> _setReminder(Map<String, dynamic> anime) async {
    final id = anime['id'] as int;

    setState(() {
      if (_reminderIds.contains(id)) {
        _reminderIds.remove(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reminder removed")),
        );
      } else {
        _reminderIds.add(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reminder set")),
        );
      }
    });

    // Send notification
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    if (await AwesomeNotifications().isNotificationAllowed()) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'reminders',
          title: 'Reminder for ${anime['title']}',
          body: 'You clicked the remind me button!',
          notificationLayout: NotificationLayout.Default,
        ),
      );
    }

    // Add to Event list
    if (!_reminderIds.contains(id)) return;
    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: anime['title'] ?? 'Unknown',
      type: 'anime',
      posterUrl: anime['image'],
      overview: anime['synopsis'],
      releaseDate: anime['airing_start'],
    );
    await widget.viewModel.addEvent(newEvent, fetchTMDB: false);
  }

  void _showAnimeDetails(Map<String, dynamic> anime) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(anime['title'] ?? 'Unknown'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (anime['image'] != null)
                Image.network(
                  anime['image'],
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 8),
              Text("Airing Start: ${anime['airing_start'] ?? 'Unknown'}"),
              const SizedBox(height: 8),
              Text(anime['synopsis'] ?? 'No description available'),
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
      appBar: AppBar(title: const Text('Upcoming Anime')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _upcomingAnime.isEmpty
          ? const Center(child: Text('No upcoming anime found'))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: _upcomingAnime.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.6,
          ),
          itemBuilder: (context, index) {
            final anime = _upcomingAnime[index];
            final isReminderSet = _reminderIds.contains(anime['id']);

            return GestureDetector(
              onTap: () => _showAnimeDetails(anime),
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
                          child: anime['image'] != null
                              ? Image.network(
                            anime['image'],
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.movie, size: 50),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            anime['title'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withOpacity(0.6),
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
                          onPressed: () => _setReminder(anime),
                          tooltip: isReminderSet ? "Remove Reminder" : "Set Reminder",
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
