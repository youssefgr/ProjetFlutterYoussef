import 'package:flutter/material.dart';
import '/Models/Yassine/event_name.dart';

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(); // title of movie/anime
  String _type = 'movie'; // default type

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Event'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
              value == null || value.isEmpty ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'movie', child: Text('Movie')),
                DropdownMenuItem(value: 'anime', child: Text('Anime')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newEvent = Event(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                type: _type,
              );
              Navigator.pop(context, newEvent); // return event
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
