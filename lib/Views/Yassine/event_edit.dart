import 'package:flutter/material.dart';
import '/Models/Yassine/event_name.dart';

class EditEventDialog extends StatefulWidget {
  final Event event;
  const EditEventDialog({super.key, required this.event});

  @override
  State<EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late String _type;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _type = widget.event.type;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEvent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
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
      ),
    );
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final updatedEvent = widget.event.copyWith(
        title: _titleController.text,
        type: _type,
      );
      Navigator.pop(context, updatedEvent);
    }
  }
}
