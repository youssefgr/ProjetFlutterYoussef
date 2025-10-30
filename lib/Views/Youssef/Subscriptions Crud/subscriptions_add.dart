import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projetflutteryoussef/Models/Youssef/subscription_you.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';

class SubscriptionsAdd extends StatefulWidget {
  const SubscriptionsAdd({super.key});

  @override
  State<SubscriptionsAdd> createState() => _SubscriptionsAddState();
}

class _SubscriptionsAddState extends State<SubscriptionsAdd> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  List<SubscriptionCycle> _selectedCycles = [];
  DateTime _nextPaymentDate = DateTime.now();

  File? _selectedImage;
  String? _savedImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSubscription,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImageUploadSection(),

              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subscription Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter the cost';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              const Text(
                'Select Cycles:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: SubscriptionCycle.values.map((category) {
                  final isSelected = _selectedCycles.contains(category);
                  return FilterChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCycles.add(category);
                        } else {
                          _selectedCycles.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: const Text('Next Payment Date'),
                subtitle: Text(
                    '${_nextPaymentDate.day}/${_nextPaymentDate.month}/${_nextPaymentDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
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
          'Subscription Image',
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
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
                onPressed: _takePhotoWithCamera,
              ),
            ),
          ],
        ),

        if (_savedImagePath != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Image saved',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyImageState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 50, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text('No image selected', style: TextStyle(color: Colors.grey[600])),
      ],
    ),
  );

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processSelectedImage(File(image.path), image.name);
    }
  }

  Future<void> _takePhotoWithCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _processSelectedImage(File(image.path), image.name);
    }
  }

  Future<void> _processSelectedImage(File imageFile, String name) async {
    final savedPath = await ImageUtils.saveImageToAppDirectory(imageFile, name);
    setState(() {
      _selectedImage = imageFile;
      _savedImagePath = savedPath;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _nextPaymentDate) {
      setState(() => _nextPaymentDate = picked);
    }
  }

  void _saveSubscription() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCycles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one cycle'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newSubscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        cost: double.parse(_costController.text),
        cycles: _selectedCycles,
        nextPaymentDate: _nextPaymentDate,
        userId: 'current_user',
        imageURL: _savedImagePath ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, newSubscription);
    }
  }
}
