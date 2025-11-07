import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_you.dart';
import 'package:projetflutteryoussef/repositories/expenses_repository.dart';
import 'package:projetflutteryoussef/Models/Youssef/expenses_models_you.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpensesAdd extends StatefulWidget {
  const ExpensesAdd({super.key});

  @override
  State<ExpensesAdd> createState() => _ExpensesAddState();
}

class _ExpensesAddState extends State<ExpensesAdd> {
  final _formKey = GlobalKey<FormState>();
  final ExpensesRepository _repository = ExpensesRepository();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  ExpensesCategory _selectedCategory = ExpensesCategory.Manga;
  DateTime _selectedDate = DateTime.now();

  File? _selectedImage;
  bool _isSubmitting = false;

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
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSubmitting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.save),
            onPressed: _isSubmitting ? null : _saveExpense,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImageUploadSection(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) =>
              (value == null || value.isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpensesCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: ExpensesCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter an amount';
                if (double.tryParse(value) == null)
                  return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: '€ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.euro),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter a price';
                if (double.tryParse(value) == null)
                  return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ IMAGE PICKER AMÉLIORÉ
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Image',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Image picker
        GestureDetector(
          onTap: () => _pickImage(ImageSource.gallery),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedImage != null
                    ? Colors.green
                    : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              color: _selectedImage != null
                  ? Colors.green.shade50
                  : Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _selectedImage != null
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Image sélectionnée',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade300,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_search,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to add image',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or use the buttons below',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Boutons d'image
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Feedback utilisateur
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Image ready',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Will be uploaded to Supabase',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload image to Supabase
      final imageUrl = await _repository.uploadExpenseImage(
        _selectedImage!.path,
        _titleController.text,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';

      final newExpense = Expenses(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        category: _selectedCategory,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        price: double.parse(_priceController.text),
        imageURL: imageUrl,
        userId: userId,
      );

      // Save to Supabase
      await _repository.addExpenseToDatabase(newExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, newExpense);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
