import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Models/Akram/media_models.dart';
import '../../../utils/image_utils.dart';

class MediaAdd extends StatefulWidget {
  const MediaAdd({super.key});

  @override
  State<MediaAdd> createState() => _MediaAddState();
}

class _MediaAddState extends State<MediaAdd> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  MediaCategory _selectedCategory = MediaCategory.film;
  MediaViewStatus _selectedStatus = MediaViewStatus.toView;
  DateTime _selectedDate = DateTime.now();
  final List<MediaGenre> _selectedGenres = [];

  File? _selectedImage;
  String? _savedImageName; // Store just the image name with extension

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMedia,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image Upload Section
              _buildImageUploadSection(),
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

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media Poster',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _selectedImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          )
              : _buildEmptyImageState(),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                onPressed: _pickImageFromGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            /*Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
                onPressed: _takePhotoWithCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),*/
          ],
        ),

        if (_savedImageName != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Image saved: $_savedImageName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],

        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Remove Image'),
            onPressed: _removeImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyImageState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _processSelectedImage(File(image.path), image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  /*Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        await _processSelectedImage(File(image.path), image.name);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }*/

  Future<void> _processSelectedImage(File imageFile, String originalName) async {
    try {
      // Save image to app directory
      final String _ = await ImageUtils.saveImageToAppDirectory(imageFile, originalName);

      setState(() {
        _selectedImage = imageFile;
        _savedImageName = originalName; // Store the image name with extension
      });

      _showSuccessSnackBar('Image saved successfully: $originalName');
    } catch (e) {
      _showErrorSnackBar('Failed to save image: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _savedImageName = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveMedia() {
    if (_formKey.currentState!.validate()) {
      final newItem = MediaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: _selectedCategory,
        title: _titleController.text,
        imageUrl: _savedImageName ?? '',
        releaseDate: _selectedDate,
        description: _descriptionController.text,
        status: _selectedStatus,
        genres: _selectedGenres,
      );

      _showSuccessSnackBar('Media added successfully!');
      Navigator.pop(context, newItem); // Return the item, don't save here
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