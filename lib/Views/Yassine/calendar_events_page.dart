import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '/viewModels/Yassine/event_viewmodel.dart';
import '/Models/Yassine/event_name.dart';

class CalendarEventsPage extends StatefulWidget {
  final EventViewModel viewModel;

  const CalendarEventsPage({super.key, required this.viewModel});

  @override
  State<CalendarEventsPage> createState() => _CalendarEventsPageState();
}

class _CalendarEventsPageState extends State<CalendarEventsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final events = widget.viewModel.events;

    // Group events by release date
    final eventsByDate = <DateTime, List<Event>>{};
    for (var event in events) {
      if (event.releaseDate != null && event.releaseDate!.isNotEmpty) {
        try {
          final parsedDate = DateTime.parse(event.releaseDate!);
          final normalized = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
          eventsByDate.putIfAbsent(normalized, () => []).add(event);
        } catch (_) {}
      }
    }

    List<Event> getEventsForDay(DateTime day) {
      final normalized = DateTime(day.year, day.month, day.day);
      return eventsByDate[normalized] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Calendar"),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            calendarFormat: CalendarFormat.month,
            eventLoader: getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text("Select a day to view events"))
                : _buildEventList(getEventsForDay(_selectedDay!)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    if (events.isEmpty) {
      return const Center(child: Text("No events on this day"));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(event.title),
            subtitle: Text(event.type),
          ),
        );
      },
    );
  }
}
