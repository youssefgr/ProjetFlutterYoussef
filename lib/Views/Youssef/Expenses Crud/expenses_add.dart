import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/utils/image_utils.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';

class ExpensesAdd extends StatefulWidget {
  const ExpensesAdd({super.key});

  @override
  State<ExpensesAdd> createState() => _ExpensesAddState();
}

class _ExpensesAddState extends State<ExpensesAdd> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Correction : l'enum par défaut doit exister dans ExpensesCategory
  ExpensesCategory _selectedCategory = ExpensesCategory.Manga;
  DateTime _selectedDate = DateTime.now();

  File? _selectedImage;
  String? _savedImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveExpense,
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<ExpensesCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ExpensesCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name), // utilise .name pour plus de lisibilité
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a price';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
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
          'Expense Image',
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
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final newExpense = Expenses(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        category: _selectedCategory,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        price: double.parse(_priceController.text),
        imageURL: _savedImagePath ?? '',
        userId: 'current_user', // a remplacer plus tard
      );

      _showSnackBar('Expense added successfully!', Colors.green);
      Navigator.pop(context, newExpense);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
