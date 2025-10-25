import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projetflutteryoussef/Models/Akram/media_models.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';

class MediaEdit extends StatefulWidget {
  final MediaItem mediaItem;

  const MediaEdit({super.key, required this.mediaItem});

  @override
  State<MediaEdit> createState() => _MediaEditState();
}

class _MediaEditState extends State<MediaEdit> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  late MediaCategory _selectedCategory;
  late MediaViewStatus _selectedStatus;
  late DateTime _selectedDate;
  late List<MediaGenre> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mediaItem.title);
    _descriptionController = TextEditingController(text: widget.mediaItem.description);

    _selectedCategory = widget.mediaItem.category;
    _selectedStatus = widget.mediaItem.status;
    _selectedDate = widget.mediaItem.releaseDate;
    _selectedGenres = List.from(widget.mediaItem.genres);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateMedia,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Info Section
              _buildImageInfoSection(),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<MediaCategory>(
                initialValue: _selectedCategory,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                items: MediaCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toString().split('.').last),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<MediaViewStatus>(
                initialValue: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
                items: MediaViewStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.toString().split('.').last),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: const Text('Release Date'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              const Text('Genres:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: MediaGenre.values.map((genre) {
                  return FilterChip(
                    label: Text(genre.toString().split('.').last),
                    selected: _selectedGenres.contains(genre),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media Poster',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (widget.mediaItem.posterUrl.isNotEmpty) ...[
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<File?>(
              future: ImageUtils.getImageFile(widget.mediaItem.posterUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Loading image...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasData && snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      snapshot.data!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Image not found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'File: ${widget.mediaItem.posterUrl}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Current Image: ${widget.mediaItem.posterUrl}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No image available'),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 8),
        Text(
          'Note: To change image, delete and recreate this media item.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  void _updateMedia() {
    if (_formKey.currentState!.validate()) {
      final updatedItem = widget.mediaItem.copyWith(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        status: _selectedStatus,
        releaseDate: _selectedDate,
        genres: _selectedGenres,
      );

      Navigator.pop(context, updatedItem); // Return the item, don't update here
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}